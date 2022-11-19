********************************************************************
***GUILTY GEAR 2 -OVERTUNE- (GUILTY GEAR 2 Enhanced Graphics Mod)***
********************************************************************


***How to Install***
Copy "d3d9.dll", "GG2OT.ini", and "Shader" folder in the same folder as "ggsx.exe". If you want to change Windows/Fullscreen mode, Press F11.




似たようなMod作ったり、他のプログラム作成する際の自分メモ用にAPIフックプログラムの原理を説明すると、

1.対象の実行ファイルで読み出されるAPIが記述されたDLLファイルのダミーを作成。
2.そのダミーDLLファイルが読みだされた(DllMain関数が実行された)際に、関数LoadLibraryでオリジナルのDLLを読み込み、GetProcAddressでアドレスを取得して別名の関数に割り当てておく。
3.基本的にダミーDLL内で記述したAPIでは、そのまま引数を別名に割り当てていたオリジナルのAPIに引き渡し、戻り値もそのまま利用するようにする。
4.何か処理が必要な場合、オリジナルのAPIに引数を渡す前に処理を行ってから引き渡す。
今回のModの場合はテクスチャ作成のAPIで特定の解像度とフォーマットだった場合に値を書き換えてオリジナルAPIに渡すように変更。

 

HRESULT APIENTRY hkIDirect3DDevice9::CreateTexture(UINT Width,UINT Height,UINT Levels,DWORD Usage,D3DFORMAT Format,D3DPOOL Pool,IDirect3DTexture9** ppTexture,HANDLE* pSharedHandle)
{

 

return m_pD3Ddev->CreateTexture(Width, Height, Levels, Usage, Format, Pool, ppTexture, pSharedHandle); return m_pD3Ddev->CreateTexture(Width, Height, Levels, Usage, Format, Pool, ppTexture, pSharedHandle);

}

 とダミーAPIではなっているところを

 

HRESULT APIENTRY hkIDirect3DDevice9::CreateTexture(UINT Width,UINT Height,UINT Levels,DWORD Usage,D3DFORMAT Format,D3DPOOL Pool,IDirect3DTexture9** ppTexture,HANDLE* pSharedHandle)
{

 

if ( (Width == 1024 && Height == 1024) && (Format == D3DFMT_R32F || Format == D3DFMT_D24S8) ) {
return m_pD3Ddev->CreateTexture(4096, 4096, Levels, Usage, Format, Pool, ppTexture, pSharedHandle);
}

 

return m_pD3Ddev->CreateTexture(Width, Height, Levels, Usage, Format, Pool, ppTexture, pSharedHandle); return m_pD3Ddev->CreateTexture(Width, Height, Levels, Usage, Format, Pool, ppTexture, pSharedHandle);

}

 

とすれば強制的にシャドウマップ用の解像度が元の縦横1024ピクセルの物から、4096ピクセルのものに切り替わる。
