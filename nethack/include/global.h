
/*
 * type xint8: small integers (typedef'd as signed,
 * in the range -127 - 127).
 */
typedef int8_t xint8;

/*
 * type coordxy: integers (typedef'd as signed,
 * in the range -32768 to 32767), mostly coordinates.
 * Note that in 2022, screen coordinates easily
 * surpass an upper limit of 127.
 */
typedef int16_t coordxy;

/*
 * type xint16: integers (typedef'd as signed,
 * in the range -32768 to 32767), non-coordinates.
 */
typedef int16_t xint16;
