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
