#ifndef FUNC_TAB_H
#define FUNC_TAB_H
#define AUTOCOMPLETE 0x0002 /* command autocompletes */
#define WIZMODECMD   0x0004 /* wizard-mode command */
#define CMD_NOT_AVAILABLE 0x0010 /* recognized but non-functional (!SHELL,&c)*/

struct ext_func_tab {
    uchar key;
    const char *ef_txt, *ef_desc;
    int (*ef_funct)(void); /* must return ECMD_foo flags */
    unsigned flags;
    const char *f_text;
};

extern struct ext_func_tab extcmdlist[];

#endif /* FUNC_TAB_H */
