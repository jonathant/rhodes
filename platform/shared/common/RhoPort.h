#ifndef _RHOPORT_H_
#define _RHOPORT_H_

#include "RhoDefs.h"

#if defined( OS_WINDOWS ) || defined( OS_WINCE )

#include <windows.h>
#include <time.h>

#define LOG_NEWLINE "\r\n"
#define LOG_NEWLINELEN 2

//typedef __int32 int32;
//typedef unsigned __int32 uint32;
typedef __int64 int64;
typedef unsigned __int64 uint64;

#define strcasecmp _stricmp
#define snprintf _snprintf
#else
#include <stdlib.h>
#include <pthread.h>
#include <wchar.h>

#undef ASSERT
#define ASSERT RHO_ASSERT

#define LOG_NEWLINE "\n"
#define LOG_NEWLINELEN 1

//typedef int32_t int32;
//typedef uint32_t uint32;
typedef long long int64;
typedef unsigned long long uint64;

#endif 

#if defined( OS_WINCE ) || defined(OS_WINDOWS) 
#define	vsnprintf	_vsnprintf
#define	vswnprintf	_vsnwprintf
#else
#define	vswnprintf vswprintf

#endif //OS_WINCE

//#include "tcmalloc/rhomem.h"

#ifdef __cplusplus
extern "C" {
#endif
	
char* str_assign_ex( char* data, int len); 
char* str_assign(char* data); 
#ifdef __cplusplus
}
#endif
		
	
#endif //_RHOPORT_H_
