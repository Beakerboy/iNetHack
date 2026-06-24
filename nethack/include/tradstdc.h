#ifdef UNWIDENED_PROTOTYPES
#define CHAR_P char
#define SCHAR_P schar
#define UCHAR_P uchar
#define XCHAR_P coordxy
#define SHORT_P short
#ifndef SKIP_BOOLEAN
#define BOOLEAN_P boolean
#endif
#define ALIGNTYP_P aligntyp
#else
#ifdef WIDENED_PROTOTYPES
#define CHAR_P int
#define SCHAR_P int
#ifndef UCHAR_P
#define UCHAR_P int
#endif
#define XCHAR_P int
#define SHORT_P int
#define BOOLEAN_P int
#define ALIGNTYP_P int
#else
/* Neither widened nor unwidened prototypes.  Argument list expansion
 * by VDECL always empty; all xxx_P vanish so defs aren't needed. */
#endif
#endif

#define NONNULLARG12
