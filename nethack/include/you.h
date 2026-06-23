#define ROLE_ALIGNS 3     /* number of permitted player alignments */
#define ROLE_GENDERS 2    /* number of permitted player genders
                             increment to 3 if you allow neuter roles */
struct Race {
    /*** Strings that name various things ***/
    const char *noun;           /* noun ("human", "elf") */
};
extern const struct Race races[]; /* Table of available races */
