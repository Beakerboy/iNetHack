/* menu return list */
typedef struct mi {
    anything item;     /* identifier */
    long count;        /* count */
    unsigned itemflags; /* item flags */
} menu_item;
#define MENU_ITEM_P struct mi
