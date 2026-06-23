#ifndef EXTERN_H
#define EXTERN_H
#ifdef INSURANCE
extern void save_currentstate(void);
#endif

/* ### invent.c ### */
extern const char *currency(long);

/* ### role.c ### */
extern boolean validrace(int, int);
extern boolean validgend(int, int, int);
extern boolean validalign(int, int, int);

/* ### save.c ### */
extern int dosave(void);

#endif /* EXTERN_H */
