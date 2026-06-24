typedef struct d_level { /* basic dungeon level element */
    xint16 dnum;          /* dungeon number */
    xint16 dlevel;        /* level number */
} d_level;
#define Lassigned(y) ((y)->dlevel || (y)->dnum)
#define Lcheck(x,z) (Lassigned(z) && on_level(x, z))
#define Is_rogue_level(x)   (Lcheck(x, &rogue_level))
