struct flag {
    boolean debug;           /* in debugging mode (aka wizard mode) */
#define wizard flags.debug
    int initrole;  /* starting role      (index into roles[])   */
    int initrace;  /* starting race      (index into races[])   */
    int initgend;  /* starting gender    (index into genders[]) */
    int initalign; /* starting alignment (index into aligns[])  */
};
extern NEARDATA struct flag flags;
