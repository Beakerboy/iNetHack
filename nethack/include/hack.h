#ifndef HACK_H
#define HACK_H
#include "config.h"
#include "dungeon.h"
#include "objclass.h"
#include "wintype.h"
#include "flag.h"

// the preprocessor is supposed to do this apparently
#define NUMMONS 5
#define FIRST_OBJECT 10

#include "display.h"
#include "you.h"


struct dgn_topology { /* special dungeon levels for speed */
    d_level d_rogue_level;
};
#define rogue_level             (svd.dungeon_topology.d_rogue_level)

#ifndef max
#define max(a, b) ((a) > (b) ? (a) : (b))
#endif
#ifndef min
#define min(x, y) ((x) < (y) ? (x) : (y))
#endif

#include "extern.h"
#include "decl.h"
#endif /* HACK_H */
