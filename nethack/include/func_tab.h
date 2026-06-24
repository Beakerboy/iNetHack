#define WIZMODECMD   0x0004 /* wizard-mode command */

struct ext_func_tab {
    uchar key;
    const char *ef_txt, *ef_desc;
    int (*ef_funct)(void); /* must return ECMD_foo flags */
    unsigned flags;
    const char *f_text;
};

extern struct ext_func_tab extcmdlist[];
