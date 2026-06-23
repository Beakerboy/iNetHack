#ifndef WINTYPE_H
#define WINTYPE_H

/* generic parameter - must not be any larger than a pointer */
typedef union any {
    genericptr_t a_void;
    struct obj *a_obj;
    struct monst *a_monst;
    int a_int;
    int a_xint16;
    int a_xint8;
    char a_char;
    schar a_schar;
    uchar a_uchar;
    unsigned int a_uint;
    long a_long;
    unsigned long a_ulong;
    coordxy a_coordxy;
    int *a_iptr;
    xint16 *a_xint16ptr;
    xint8 *a_xint8ptr;
    long *a_lptr;
    coordxy *a_coordxyptr;
    unsigned long *a_ulptr;
    unsigned *a_uptr;
    const char *a_string;
    int (*a_nfunc)(void);
    unsigned long a_mask32; /* used by status highlighting */
    int64 a_int64;
    uint64 a_uint64;
    /* add types as needed */
} anything;
#define ANY_P union any /* avoid typedef in prototypes
                         * (buggy old Ultrix compiler) */

/* menu return list */
typedef struct mi {
    anything item;     /* identifier */
    long count;        /* count */
    unsigned itemflags; /* item flags */
} menu_item;
#define MENU_ITEM_P struct mi
