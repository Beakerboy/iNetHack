// Not really, just filling it in.
enum glyph_offsets {
    GLYPH_MON_OFF = 0,
    GLYPH_MON_MALE_OFF = (GLYPH_MON_OFF),
    GLYPH_MON_FEM_OFF = (5 + GLYPH_MON_MALE_OFF),
    GLYPH_PET_OFF = (5 + GLYPH_MON_FEM_OFF),
    GLYPH_PET_MALE_OFF = (GLYPH_PET_OFF),
    GLYPH_PET_FEM_OFF = (5 + GLYPH_PET_MALE_OFF),
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
