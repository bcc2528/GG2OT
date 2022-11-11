// MMJ's Cel Shader - v1.02
//
// ----------------------------------------------------------------
// Special thanks go out to Maruke for his CComic shader,
// and for allowing me to release this shader based upon his work.
// ----------------------------------------------------------------
//
// 1 - Pencil Mode
// 2 - 1/3 Strength
// 3 - 2/3 Strength
// 4 - Full Strength
//
// -----------
// MegaManJuno
//


//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------
static float Mode = 2.0;
static float3 GSParam = {Mode, Mode, (Mode - 1.0)};
float fwidth = 1280.0;
float fheight = 720.0;


//-----------------------------------------------------------------------------
// Texture samplers
//-----------------------------------------------------------------------------
texture RenderTargetTexture;
sampler RenderTargetSampler = 
sampler_state
{
    Texture = <RenderTargetTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;

    AddressU = Clamp;
    AddressV = Clamp;
};

texture MeshTexture;
sampler MeshTextureSampler = 
sampler_state
{
    Texture = <MeshTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;

    AddressU = Clamp;
    AddressV = Clamp;
};


texture DepthRenderTarget;
sampler DepthSampler = 
sampler_state
{
    Texture = <DepthRenderTarget>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;

    AddressU = Clamp;
    AddressV = Clamp;
};


//-----------------------------------------------------------------------------
// Vertex shader output structure
//-----------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 Position : POSITION;
    float3 TextureUV : TEXCOORD0;
    float4 Diffuse : TEXCOORD1;
};
struct PS_OUTPUT
{
    float4 Color : Color0;
    float4 Depth : Color1;
};


float3 RGB2HSL(in float3 cRGB) {
    float vH, vS, vL, cR, cG, cB, vMin, vMax, dMax, dR, dG, dB;


    cR = cRGB[0]; cG = cRGB[1]; cB = cRGB[2];


    vMin = min(min(cR, cG), cB); vMax = max(max(cR, cG), cB);
    dMax = vMax - vMin;


    vL = (vMax + vMin) / 2.0;


    // gray, no chroma
    if(dMax == 0.0) {
        vH = 0.0; vS = 0.0;


    // chromatic data
    } else {
        if(vL < 0.5) { vS = dMax / (vMax + vMin); }
        else         { vS = dMax / (2.0 - vMax - vMin); }


        dR = (((vMax - cR) / 6.0) + (dMax / 2.0)) / dMax;
        dG = (((vMax - cG) / 6.0) + (dMax / 2.0)) / dMax;
        dB = (((vMax - cB) / 6.0) + (dMax / 2.0)) / dMax;


        if     (cR >= vMax) { vH = dB - dG; }
        else if(cG >= vMax) { vH = (1.0 / 3.0) + dR - dB; }
        else if(cB >= vMax) { vH = (2.0 / 3.0) + dG - dR; }


        if     (vH < 0.0) { vH += 1.0; }
        else if(vH > 1.0) { vH -= 1.0; }
    }
    return float3(vH, vS, vL);
}


float Hue2RGB(in float v1, in float v2, in float vH) {
    float v3;


    if     (vH < 0.0) { vH += 1.0; }
    else if(vH > 1.0) { vH -= 1.0; }


    if     ((6.0 * vH) < 1.0) { v3 = v1 + (v2 - v1) * 6.0 * vH; }
    else if((2.0 * vH) < 1.0) { v3 = v2; }
    else if((3.0 * vH) < 2.0) { v3 = v1 + (v2 - v1) * ((2.0 / 3.0) - vH) * 6.0; }
    else                      { v3 = v1; }


    return v3;
}


float3 HSL2RGB(in float3 vHSL) {
    float cR, cG, cB, v1, v2;


    if(vHSL[1] == 0.0) {
        cR = vHSL[2]; cG = vHSL[2]; cB = vHSL[2];


    } else {
        if(vHSL[2] < 0.5) { v2 = vHSL[2] * (1.0 + vHSL[1] ); }
        else              { v2 = (vHSL[2] + vHSL[1] ) - (vHSL[1] * vHSL[2] ); }


        v1 = 2.0 * vHSL[2] - v2;


        cR = Hue2RGB(v1, v2, vHSL[0] + (1.0 / 3.0));
        cG = Hue2RGB(v1, v2, vHSL[0] );
        cB = Hue2RGB(v1, v2, vHSL[0] - (1.0 / 3.0));
    }
    return float3(cR, cG, cB);
}


float3 colorAdjust(in float3 cRGB) {
    float3 cHSL;
    float cr, sl, ml, ms, aw, ab;


    cHSL = RGB2HSL(cRGB);


    // absolute white level cutoff
    aw = 0.9675; // default: 0.9675


    // absolute black level cutoff
    ab = 0.0325; // default: 0.0325


    // number of shading levels (not counting absolute white and black levels)
    sl = 9.0; // default: 7.0


    // color range per shading level
    cr = 0.5 / sl; // default: 1.0 / sl


    // modification value for color adjustment
    ml = cHSL[2] % cr; // default: mod(cHSL[2], cr)


    // saturation modifier
    ms = 1.15; // default: 1.2


    // normal modes
    if(GSParam.z > 0.0) {
        if     (cHSL[2] > aw) { cHSL[1]  = 1.0; cHSL[2]  = 1.0; }
        else if(cHSL[2] > ab) { cHSL[1] *= ms;  cHSL[2] += ((cr * (cHSL[2] + 0.6)) - ml); }
        else                  { cHSL[1]  = 0.0; cHSL[2]  = 0.0; }
        cHSL[2] = clamp(cHSL[2], float(int(cHSL[2] / cr) - 1) * cr, float(int(cHSL[2] / cr) + 1) * cr);
        cRGB = HSL2RGB(cHSL);


    // pencil mode
    } else {
        if     (cHSL[2] + 0.2 > aw) { cRGB = float3(1.0, 1.0, 1.0); }
        else if (cHSL[2] > ab)       { cRGB = float3(cHSL[2] + ((cr * (cHSL[2] + 0.65)) - ml + 0.2), cHSL[2] + ((cr * (cHSL[2] + 0.65)) - ml + 0.2), cHSL[2] + ((cr * (cHSL[2] + 0.65)) - ml + 0.2)); }
        else                        { cRGB = float3(0.2, 0.2, 0.2); }
    }
    return cRGB;
}


//-----------------------------------------------------------------------------
// Name: Cartoon
//-----------------------------------------------------------------------------
float4 Cartoon( in float2 OriginalUV : TEXCOORD0 ) : COLOR 
{
     float dx;
     float dy;
     
     if((fwidth / 2.0) <= 1280)
     {
            dx = 1.0 /  (fwidth);
     }
     else
     {
            dx = 1.0 /  (fwidth / 2.0);
     }
     if((fheight / 2.0) <= 720)
     {
            dy = 1.0 /  (fheight);
     }
     else
     {
            dy = 1.0 /  (fheight / 2.0);
     }

     float3  h, hz, o, c0, c2, c4, c6, c8, c9, cz, c1, c3, c5, c7;
     float i, k, kz, mo, a0;

    // outline modifier
    mo = 0.2; // default: mo = 0.2

     float4 output;
     c0 = tex2D(RenderTargetSampler, OriginalUV + float2(-dx,-dy)).rgb;
     c1 = tex2D(RenderTargetSampler, OriginalUV + float2(0,-dy)).rgb;
     c2 = tex2D(RenderTargetSampler, OriginalUV + float2(dx,-dy)).rgb;
     c3 = tex2D(RenderTargetSampler, OriginalUV + float2(-dx,0)).rgb;
     c4 = tex2D(RenderTargetSampler, OriginalUV).rgb;
     c5 = tex2D(RenderTargetSampler, OriginalUV + float2(dx,0)).rgb;
     c6 = tex2D(RenderTargetSampler, OriginalUV + float2(-dx,dy)).rgb;
     c7 = tex2D(RenderTargetSampler, OriginalUV + float2(0,dy)).rgb;
     c8 = tex2D(RenderTargetSampler, OriginalUV + float2(dx,dy)).rgb;
     a0 = tex2D(RenderTargetSampler, OriginalUV + float2(0,0)).a;


    c9 = (c0 * 5.0 + c1 * 10.0 + c2 * 5.0 + c3 * 10.0 + c4 * 4.0 + c5 * 10.0 + c6 * 5.0 + c7 * 10.0 + c8 * 5.0) / 64.0;


    o = float3(1.0, 1.0, 1.0); h = float3(0.05, 0.05, 0.05); hz = h; k = 0.01; kz = 0.0035;


    cz  = (c4 + h) / (dot(o, c4) + k);


    hz = (cz - ((c0 + h) / (dot(o, c0) + k))); i  = kz / (dot(hz, hz) + kz);
    hz = (cz - ((c1 + h) / (dot(o, c1) + k))); i += kz / (dot(hz, hz) + kz);
    hz = (cz - ((c2 + h) / (dot(o, c2) + k))); i += kz / (dot(hz, hz) + kz);
    hz = (cz - ((c3 + h) / (dot(o, c3) + k))); i += kz / (dot(hz, hz) + kz);
    hz = (cz - ((c5 + h) / (dot(o, c5) + k))); i += kz / (dot(hz, hz) + kz);
    hz = (cz - ((c6 + h) / (dot(o, c6) + k))); i += kz / (dot(hz, hz) + kz);
    hz = (cz - ((c7 + h) / (dot(o, c7) + k))); i += kz / (dot(hz, hz) + kz);
    hz = (cz - ((c8 + h) / (dot(o, c8) + k))); i += kz / (dot(hz, hz) + kz);


    i /= 8.0;


    if(GSParam.z < 2.0) {
        if(GSParam.z == 0.0) { // Pencil Mode
            c9 = colorAdjust(c9) * i;
            if(c9.r < 0.2) { c9.rgb = float3(0.2, 0.2, 0.2); }
            output.a = a0;
            output.rgb = c9;
            return output;


        } else { // 1/3 strength
            if(i < mo) { i = mo; }
            c9 = min(o, min(c9, c9 + dot(o, c9)));
            output.rgb = lerp(c4, colorAdjust(c9), 0.33) * i;
            output.a = a0;
            return output;
        }


    } else {
        if(GSParam.z == 2.0) { // 2/3 strength
            if(i < mo) { i = mo; }
            c9 = min(o, min(c9, c9 + dot(o, c9)));
            output.rgb = lerp(c4, colorAdjust(c9), 0.67) * i;
            output.a = a0;
            return output;


        } else { // Full strength
            if(i < mo) { i = mo; }
            c9 = min(o, min(c9, c9 + dot(o, c9)));
            output.rgb = colorAdjust(c9) * i;
            output.a = a0;
            return output;
        }
    }
     
    return output;
}


technique TechCartoon
{
    pass P0
    {        
        PixelShader = compile ps_3_0 Cartoon();

    }
}

