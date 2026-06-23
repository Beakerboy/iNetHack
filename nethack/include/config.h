#include "tradstdc.h"

#ifdef AZTEC
#define schar char
#else
typedef signed char schar;
#endif

/*
 * type uchar:
 * small unsigned integers (8 bits suffice - but 7 bits do not)
 *      typedef unsigned char uchar;
 * will be satisfactory if you have an "unsigned char" type; otherwise use
 *      typedef unsigned short int uchar;
 */
#ifndef _AIX32 /* identical typedef in system file causes trouble */
typedef unsigned char uchar;
#endif

#include "global.h"
