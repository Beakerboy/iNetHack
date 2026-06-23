struct RoleName {
    const char *m; /* name when character is male */
    const char *f; /* when female; null if same as male */
};

struct Align {
    const char *adj;      /* lawful/neutral/chaotic */
};
#define ROLE_ALIGNS 3     /* number of permitted player alignments */
extern const struct Align aligns[]; /* table of available alignments */

/*** Unified structure specifying gender information ***/
struct Gender {
    const char *adj;      /* male/female/neuter */
};
#define ROLE_GENDERS 2    /* number of permitted player genders
                             increment to 3 if you allow neuter roles */
extern const struct Gender genders[]; /* table of available genders */

/*** Unified structure containing role information ***/
struct Role {
    /*** Strings that name various things ***/
    struct RoleName name;    /* the role's name (from u_init.c) */
    const char *filecode;           /* abbreviation for use in file names */
};
extern const struct Role roles[]; /* table of available roles */

struct Race {
    /*** Strings that name various things ***/
    const char *noun;           /* noun ("human", "elf") */
};
extern const struct Race races[]; /* Table of available races */

/*** Information about the player ***/
struct you {
    coordxy ux, uy;     /* current map coordinates */
    d_level uz, uz0;    /* your level on this and the previous turn */
    int mh, mhmax,              /* current and max hit points when polyd */
        mtimedone;              /* no. of turns until polymorph times out */
    int uhp, uhpmax;         /* hit points, aka health */
    long umoney0;
}; /* end of `struct you' */
