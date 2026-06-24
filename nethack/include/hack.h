#ifndef HACK_H
#define HACK_H
#include "config.h"
#include "dungeon.h"
#include "wintype.h"
#include "flag.h"
#include "display.h"
#include "you.h"


struct dgn_topology { /* special dungeon levels for speed */
    d_level d_rogue_level;
};
#define rogue_level             (svd.dungeon_topology.d_rogue_level)

#include "extern.h"
#include "decl.h"
#endif /* HACK_H */
