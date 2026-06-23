/* generic pointer, always a macro; genericptr_t is usually a typedef */
#define genericptr void *
#ifndef genericptr_t
typedef genericptr genericptr_t; /* (void *) or (char *) */
#endif
