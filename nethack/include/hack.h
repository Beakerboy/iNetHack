#ifndef HACK_H
#define HACK_H
#include "config.h"
#include "dungeon.h"
#include "wintype.h"
#include "flag.h"
#include "display.h"
#include "you.h"
#include "extern.h"
#include "decl.h"

struct dgn_topology { /* special dungeon levels for speed */
    d_level d_rogue_level;
};

// Not exactly copied
#define rogue_level             (svd.dungeon_topology.d_rogue_level)

#endif /* HACK_H */
