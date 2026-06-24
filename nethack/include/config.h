#include "patchlevel.h"

#ifdef AZTEC
#define schar char
#else
typedef signed char schar;
#endif

#ifndef _AIX32 /* identical typedef in system file causes trouble */
typedef unsigned char uchar;
#endif

#include "tradstdc.h"

#include "integer.h"
#include "global.h"

/*
 *      Defining INSURANCE slows down level changes, but allows games that
 *      died due to program or system crashes to be resumed from the point
 *      of the last level change, after running a utility program.
 */
#define INSURANCE /* allow crashed game recovery */
#define NEARDATA
