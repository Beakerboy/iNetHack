#ifndef EXTERN_H
#define EXTERN_H

#include "permonst.h"

/* ### do.c ### */
#ifdef INSURANCE
extern void save_currentstate(void);
#endif

/* ### dungeon.c ### */
extern boolean on_level(d_level *, d_level *) NONNULLARG12;

/* ### invent.c ### */
extern const char *currency(long);

/* ### role.c ### */
extern boolean validrace(int, int);
extern boolean validgend(int, int, int);
extern boolean validalign(int, int, int);

/* ### save.c ### */
extern int dosave(void);

#endif /* EXTERN_H */
