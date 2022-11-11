#define WIN32_LEAN_AND_MEAN

#ifndef _MAIN_H
#define _MAIN_H

#undef SHADER_DEBUG //define this for shader debugging logs

#define VERSION "0.1"

#define INTERCEPTOR_NAME "GG2OT"
#define SETTINGS_FILE_NAME (INTERCEPTOR_NAME".ini")

char *GetDirectoryFile(char *filename);
void __cdecl add_log (const char * fmt, ...);

#endif