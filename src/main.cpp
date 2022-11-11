#define _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES 1
#include <windows.h>
#include <tlhelp32.h>
#include <fstream>
#include <ostream>
#include <iostream>
#include <stdio.h>

#include "main.h"
#include "d3d9.h"
#include "Settings.h"

//Globals
using namespace std;
std::ofstream ofile;	
char dlldir[320];

int WINAPI D3DPERF_BeginEvent(DWORD color, LPCWSTR name);
int WINAPI D3DPERF_EndEvent();
void WINAPI D3DPERF_SetOption(DWORD dwOptions);

typedef int (APIENTRY *tD3DPERF_BeginEvent)(DWORD, LPCWSTR);
typedef int (APIENTRY *tD3DPERF_EndEvent)();
typedef void (WINAPI *tD3DPERF_SetOptions)(DWORD);

tD3DPERF_BeginEvent oD3DPERF_BeginEvent;
tD3DPERF_EndEvent oD3DPERF_EndEvent;
tD3DPERF_SetOptions oD3DPERF_SetOptions;

int APIENTRY D3DPERF_BeginEvent(DWORD color, LPCWSTR name)
{
	return oD3DPERF_BeginEvent(color, name);
}

int APIENTRY D3DPERF_EndEvent()
{
	return oD3DPERF_EndEvent();
}

void WINAPI D3DPERF_SetOptions(DWORD dwOptions)
{
	oD3DPERF_SetOptions(dwOptions);
}

/*DWORD GetProcessIdByName(const wchar_t *processName)
{

	auto entry = PROCESSENTRY32{ sizeof(PROCESSENTRY32) };

	auto hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

	if (Process32First(hSnapshot, &entry))
	{
		do
		{
			if (wcsstr(processName, entry.szExeFile))
			{
				CloseHandle(hSnapshot);
				return entry.th32ProcessID;
			}
		} while (Process32Next(hSnapshot, &entry));
	}

	CloseHandle(hSnapshot);
	return -1;
}*/

DWORD GetProcessIdByName(char *processName)
{

	auto entry = PROCESSENTRY32{ sizeof(PROCESSENTRY32) };

	auto hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

	if (Process32First(hSnapshot, &entry))
	{
		do
		{
			if (strcmp(processName, entry.szExeFile))
			{
				add_log("OK %d", entry.th32ProcessID);
				CloseHandle(hSnapshot);
				return entry.th32ProcessID;
			}
		} while (Process32Next(hSnapshot, &entry));
	}

	CloseHandle(hSnapshot);
	return -1;
}

bool WINAPI DllMain(HMODULE hDll, DWORD dwReason, PVOID pvReserved)
{
	if(dwReason == DLL_PROCESS_ATTACH)
	{
		DisableThreadLibraryCalls(hDll);
		GetModuleFileName(hDll, dlldir, 512);
		for(int i = strlen(dlldir); i > 0; i--) { if(dlldir[i] == '\\') { dlldir[i+1] = 0; break; } }
		ofile.open(GetDirectoryFile("d3dlog.txt"), ios::app);

		//Load Settings
		Settings::get().load();
		Settings::get().report();

		char sysd3d[320];
		GetSystemDirectory(sysd3d, 320);
		strcat(sysd3d, "\\d3d9.dll");
	
		//HMODULE hMod = LoadLibrary(sysd3d);
		HMODULE hMod = LoadLibraryEx(sysd3d, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
		oD3DPERF_BeginEvent = (tD3DPERF_BeginEvent)GetProcAddress(hMod, "D3DPERF_BeginEvent");
		oD3DPERF_EndEvent = (tD3DPERF_EndEvent)GetProcAddress(hMod, "D3DPERF_EndEvent");
		oDirect3DCreate9 = (tDirect3DCreate9)GetProcAddress(hMod, "Direct3DCreate9");

		if (Settings::get().getCPUHighPriority())
		{
			
			HANDLE ggsx_id = (HANDLE)GetProcessIdByName("ggsx.exe");
			SetPriorityClass(ggsx_id, THREAD_PRIORITY_HIGHEST);
			add_log("change pri %d", GetProcessIdByName("ggsx.exe"));
			//SetPriorityClass(GetCurrentProcess(), THREAD_PRIORITY_HIGHEST);
		}

		return true;
	}

	else if(dwReason == DLL_PROCESS_DETACH)
	{
		if(ofile) { ofile.close(); }
	}

    return false;
}

char *GetDirectoryFile(char *filename)
{
	static char path[320];
	strcpy(path, dlldir);
	strcat(path, filename);
	return path;
}

void __cdecl add_log (const char *fmt, ...)
{
	if(ofile)
	{
		if(!fmt) { return; }

		va_list va_alist;
		char logbuf[9999] = {0};

		va_start (va_alist, fmt);
		_vsnprintf_s(logbuf+strlen(logbuf), sizeof(logbuf) - strlen(logbuf), _TRUNCATE, fmt, va_alist);
		va_end (va_alist);

		ofile << logbuf << std::endl;
	}
}

