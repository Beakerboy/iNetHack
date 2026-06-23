enum monnums {
        NUMMONS,
        NON_PM = -1,              /* "not a monster" */
        LOW_PM = NON_PM + 1,      /* first monster in mons */
        LEAVESTATUE = NON_PM - 1, /* leave statue instead of corpse;
                                   * there are two lower values assigned
                                   * in end.c so that (x == LEAVESTATUE)
                                   * will test FALSE in bones.c:
                                   *  (NON_PM - 2) for no corpse
                                   *  (NON_PM - 3) for no corpse, no grave */
        HIGH_PM = NUMMONS - 1,
};
