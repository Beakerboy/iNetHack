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
struct Race {
    /*** Strings that name various things ***/
    const char *noun;           /* noun ("human", "elf") */
};
extern const struct Race races[]; /* Table of available races */
