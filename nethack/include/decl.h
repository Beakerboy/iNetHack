extern NEARDATA struct you u;
extern NEARDATA winid WIN_MAP, WIN_INVEN;

struct instance_globals_saved_d {
    /* dungeon.c */
    //dungeon dungeons[MAXDUNGEON]; /* ini'ed by init_dungeon() */
    struct dgn_topology dungeon_topology;
    /* decl.c */
    //dest_area dndest;
    //coord *doors; /* array of door locations */
    //int doors_alloc; /* doors-array allocated size */
    /* o_init.c */
    //short disco[NUM_OBJECTS];
};
extern struct instance_globals_saved_d svd;
