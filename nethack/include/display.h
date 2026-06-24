#ifndef DISPLAY_H
#define DISPLAY_H
#define NUMMONS 5
// Not really, just filling it in.
enum glyph_offsets {
    GLYPH_MON_OFF = 0,
    GLYPH_MON_MALE_OFF = (GLYPH_MON_OFF),
    GLYPH_MON_FEM_OFF = (NUMMONS + GLYPH_MON_MALE_OFF),
    GLYPH_PET_OFF = (NUMMONS + GLYPH_MON_FEM_OFF),
    GLYPH_PET_MALE_OFF = (GLYPH_PET_OFF),
    GLYPH_PET_FEM_OFF = (NUMMONS + GLYPH_PET_MALE_OFF),
    GLYPH_BODY_OFF = (NUMMONS + GLYPH_PET_FEM_OFF),
    GLYPH_PILETOP_OFF = (NUMMONS + GLYPH_BODY_OFF),
    GLYPH_OBJ_PILETOP_OFF = (GLYPH_PILETOP_OFF),
    GLYPH_BODY_PILETOP_OFF = (NUM_OBJECTS + GLYPH_OBJ_PILETOP_OFF),
    GLYPH_STATUE_MALE_PILETOP_OFF = (NUMMONS + GLYPH_BODY_PILETOP_OFF),
    GLYPH_STATUE_FEM_PILETOP_OFF = (NUMMONS + GLYPH_STATUE_MALE_PILETOP_OFF),
    MAX_GLYPH
};
#define NO_GLYPH          MAX_GLYPH
#define glyph_is_female_pet(glyph) \
    ((glyph) >= GLYPH_PET_FEM_OFF && (glyph) < (GLYPH_PET_FEM_OFF + 5))
#define glyph_is_male_pet(glyph) \
    ((glyph) >= GLYPH_PET_MALE_OFF                      \
     && (glyph) < (GLYPH_PET_MALE_OFF + 5))
#define glyph_is_pet(glyph) \
    (glyph_is_male_pet(glyph) || glyph_is_female_pet(glyph))
#define glyph_is_body_piletop(glyph) \
    (((glyph) >= GLYPH_BODY_PILETOP_OFF)                        \
     && ((glyph) < (GLYPH_BODY_PILETOP_OFF + NUMMONS)))
#define glyph_is_body(glyph) \
    ((((glyph) >= GLYPH_BODY_OFF) && ((glyph) < (GLYPH_BODY_OFF + NUMMONS))) \
     || glyph_is_body_piletop(glyph))
#define glyph_is_fem_statue_piletop(glyph) \
    (((glyph) >= GLYPH_STATUE_FEM_PILETOP_OFF)                  \
      && ((glyph) < (GLYPH_STATUE_FEM_PILETOP_OFF + NUMMONS)))
#define glyph_is_male_statue_piletop(glyph) \
    (((glyph) >= GLYPH_STATUE_MALE_PILETOP_OFF)                 \
         && ((glyph) < (GLYPH_STATUE_MALE_PILETOP_OFF + NUMMONS)))
#define glyph_is_fem_statue(glyph) \
    ((((glyph) >= GLYPH_STATUE_FEM_OFF)                         \
      && ((glyph) < (GLYPH_STATUE_FEM_OFF + NUMMONS)))          \
     || glyph_is_fem_statue_piletop(glyph))
#define glyph_is_male_statue(glyph) \
    ((((glyph) >= GLYPH_STATUE_MALE_OFF)                        \
      && ((glyph) < (GLYPH_STATUE_MALE_OFF + NUMMONS)))         \
     || glyph_is_male_statue_piletop(glyph))
#define glyph_is_statue(glyph) \
    (glyph_is_male_statue(glyph) || glyph_is_fem_statue(glyph))
#define glyph_is_normal_generic_obj(glyph) \
    ((glyph) > GLYPH_OBJ_OFF && (glyph) < GLYPH_OBJ_OFF + FIRST_OBJECT - 1)
#define glyph_is_piletop_generic_obj(glyph) \
    ((glyph) > GLYPH_OBJ_PILETOP_OFF                            \
     && (glyph) < GLYPH_OBJ_PILETOP_OFF + FIRST_OBJECT - 1)
#define glyph_is_generic_object(glyph) \
    (glyph_is_normal_generic_obj(glyph)                         \
     || glyph_is_piletop_generic_obj(glyph))
#define glyph_is_normal_object(glyph) \
    ((glyph) == GLYPH_OBJ_OFF                                   \
     || ((glyph) >= GLYPH_OBJ_OFF + FIRST_OBJECT - 1            \
         && (glyph) < (GLYPH_OBJ_OFF + NUM_OBJECTS))            \
     || glyph_is_normal_piletop_obj(glyph))
#define glyph_is_object(glyph) \
    (glyph_is_normal_object(glyph) || glyph_is_generic_object(glyph)    \
     || glyph_is_statue(glyph) || glyph_is_body(glyph))
#endif /* DISPLAY_H */
