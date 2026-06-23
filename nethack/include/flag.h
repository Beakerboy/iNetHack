struct flag {
    int initrole;  /* starting role      (index into roles[])   */
    int initrace;  /* starting race      (index into races[])   */
    int initgend;  /* starting gender    (index into genders[]) */
    int initalign; /* starting alignment (index into aligns[])  */
};
extern NEARDATA struct flag flags;
