struct flag {
    boolean debug;           /* in debugging mode (aka wizard mode) */
#define wizard flags.debug
    int initrole;  /* starting role      (index into roles[])   */
    int initrace;  /* starting race      (index into races[])   */
    int initgend;  /* starting gender    (index into genders[]) */
    int initalign; /* starting alignment (index into aligns[])  */
};

struct instance_flags {
    boolean wc_color;         /* use color graphics                  */
};
#define use_color wc_color

extern NEARDATA struct flag flags;
extern NEARDATA struct instance_flags iflags;
