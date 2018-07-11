
--hb-ot.h from harfbuzz 1.8.2

local ffi = require'ffi'
require'harfbuzz_h'
ffi.cdef[[

// hb-ot-font.h --------------------------------------------------------------

void hb_ot_font_set_funcs (hb_font_t *font);

// hb-ot-layout.h ------------------------------------------------------------

hb_bool_t
hb_ot_layout_has_glyph_classes (hb_face_t *face);
typedef enum {
  HB_OT_LAYOUT_GLYPH_CLASS_UNCLASSIFIED = 0,
  HB_OT_LAYOUT_GLYPH_CLASS_BASE_GLYPH = 1,
  HB_OT_LAYOUT_GLYPH_CLASS_LIGATURE = 2,
  HB_OT_LAYOUT_GLYPH_CLASS_MARK = 3,
  HB_OT_LAYOUT_GLYPH_CLASS_COMPONENT = 4
} hb_ot_layout_glyph_class_t;
hb_ot_layout_glyph_class_t
hb_ot_layout_get_glyph_class (hb_face_t *face,
         hb_codepoint_t glyph);
void
hb_ot_layout_get_glyphs_in_class (hb_face_t *face,
      hb_ot_layout_glyph_class_t klass,
      hb_set_t *glyphs );
unsigned int
hb_ot_layout_get_attach_points (hb_face_t *face,
    hb_codepoint_t glyph,
    unsigned int start_offset,
    unsigned int *point_count ,
    unsigned int *point_array );
unsigned int
hb_ot_layout_get_ligature_carets (hb_font_t *font,
      hb_direction_t direction,
      hb_codepoint_t glyph,
      unsigned int start_offset,
      unsigned int *caret_count ,
      hb_position_t *caret_array );
enum {
	HB_OT_LAYOUT_NO_SCRIPT_INDEX = 0xFFFFu,
	HB_OT_LAYOUT_NO_FEATURE_INDEX = 0xFFFFu,
	HB_OT_LAYOUT_DEFAULT_LANGUAGE_INDEX = 0xFFFFu,
	HB_OT_LAYOUT_NO_VARIATIONS_INDEX = 0xFFFFFFFFu,
};
unsigned int
hb_ot_layout_table_get_script_tags (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int start_offset,
        unsigned int *script_count ,
        hb_tag_t *script_tags );
hb_bool_t
hb_ot_layout_table_find_script (hb_face_t *face,
    hb_tag_t table_tag,
    hb_tag_t script_tag,
    unsigned int *script_index);
hb_bool_t
hb_ot_layout_table_choose_script (hb_face_t *face,
      hb_tag_t table_tag,
      const hb_tag_t *script_tags,
      unsigned int *script_index,
      hb_tag_t *chosen_script);
unsigned int
hb_ot_layout_table_get_feature_tags (hb_face_t *face,
         hb_tag_t table_tag,
         unsigned int start_offset,
         unsigned int *feature_count ,
         hb_tag_t *feature_tags );
unsigned int
hb_ot_layout_script_get_language_tags (hb_face_t *face,
           hb_tag_t table_tag,
           unsigned int script_index,
           unsigned int start_offset,
           unsigned int *language_count ,
           hb_tag_t *language_tags );
hb_bool_t
hb_ot_layout_script_find_language (hb_face_t *face,
       hb_tag_t table_tag,
       unsigned int script_index,
       hb_tag_t language_tag,
       unsigned int *language_index);
hb_bool_t
hb_ot_layout_language_get_required_feature_index (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int script_index,
        unsigned int language_index,
        unsigned int *feature_index);
hb_bool_t
hb_ot_layout_language_get_required_feature (hb_face_t *face,
         hb_tag_t table_tag,
         unsigned int script_index,
         unsigned int language_index,
         unsigned int *feature_index,
         hb_tag_t *feature_tag);
unsigned int
hb_ot_layout_language_get_feature_indexes (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int script_index,
        unsigned int language_index,
        unsigned int start_offset,
        unsigned int *feature_count ,
        unsigned int *feature_indexes );
unsigned int
hb_ot_layout_language_get_feature_tags (hb_face_t *face,
     hb_tag_t table_tag,
     unsigned int script_index,
     unsigned int language_index,
     unsigned int start_offset,
     unsigned int *feature_count ,
     hb_tag_t *feature_tags );
hb_bool_t
hb_ot_layout_language_find_feature (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int script_index,
        unsigned int language_index,
        hb_tag_t feature_tag,
        unsigned int *feature_index);
unsigned int
hb_ot_layout_feature_get_lookups (hb_face_t *face,
      hb_tag_t table_tag,
      unsigned int feature_index,
      unsigned int start_offset,
      unsigned int *lookup_count ,
      unsigned int *lookup_indexes );
unsigned int
hb_ot_layout_table_get_lookup_count (hb_face_t *face,
         hb_tag_t table_tag);
void
hb_ot_layout_collect_lookups (hb_face_t *face,
         hb_tag_t table_tag,
         const hb_tag_t *scripts,
         const hb_tag_t *languages,
         const hb_tag_t *features,
         hb_set_t *lookup_indexes );
void
hb_ot_layout_lookup_collect_glyphs (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int lookup_index,
        hb_set_t *glyphs_before,
        hb_set_t *glyphs_input,
        hb_set_t *glyphs_after,
        hb_set_t *glyphs_output );
hb_bool_t
hb_ot_layout_table_find_feature_variations (hb_face_t *face,
         hb_tag_t table_tag,
         const int *coords,
         unsigned int num_coords,
         unsigned int *variations_index );
unsigned int
hb_ot_layout_feature_with_variations_get_lookups (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int feature_index,
        unsigned int variations_index,
        unsigned int start_offset,
        unsigned int *lookup_count ,
        unsigned int *lookup_indexes );
hb_bool_t
hb_ot_layout_has_substitution (hb_face_t *face);
hb_bool_t
hb_ot_layout_lookup_would_substitute (hb_face_t *face,
          unsigned int lookup_index,
          const hb_codepoint_t *glyphs,
          unsigned int glyphs_length,
          hb_bool_t zero_context);
void
hb_ot_layout_lookup_substitute_closure (hb_face_t *face,
            unsigned int lookup_index,
            hb_set_t *glyphs
                                     );
void
hb_ot_layout_lookups_substitute_closure (hb_face_t *face,
                                         const hb_set_t *lookups,
                                         hb_set_t *glyphs);
hb_bool_t
hb_ot_layout_has_positioning (hb_face_t *face);
hb_bool_t
hb_ot_layout_get_size_params (hb_face_t *face,
         unsigned int *design_size,
         unsigned int *subfamily_id,
         unsigned int *subfamily_name_id,
         unsigned int *range_start,
         unsigned int *range_end );

// hb-ot-tag.h ---------------------------------------------------------------

void
hb_ot_tags_from_script (hb_script_t script,
   hb_tag_t *script_tag_1,
   hb_tag_t *script_tag_2);
hb_script_t
hb_ot_tag_to_script (hb_tag_t tag);
hb_tag_t
hb_ot_tag_from_language (hb_language_t language);
hb_language_t
hb_ot_tag_to_language (hb_tag_t tag);

// hb-ot-math.h --------------------------------------------------------------

typedef enum {
  HB_OT_MATH_CONSTANT_SCRIPT_PERCENT_SCALE_DOWN = 0,
  HB_OT_MATH_CONSTANT_SCRIPT_SCRIPT_PERCENT_SCALE_DOWN = 1,
  HB_OT_MATH_CONSTANT_DELIMITED_SUB_FORMULA_MIN_HEIGHT = 2,
  HB_OT_MATH_CONSTANT_DISPLAY_OPERATOR_MIN_HEIGHT = 3,
  HB_OT_MATH_CONSTANT_MATH_LEADING = 4,
  HB_OT_MATH_CONSTANT_AXIS_HEIGHT = 5,
  HB_OT_MATH_CONSTANT_ACCENT_BASE_HEIGHT = 6,
  HB_OT_MATH_CONSTANT_FLATTENED_ACCENT_BASE_HEIGHT = 7,
  HB_OT_MATH_CONSTANT_SUBSCRIPT_SHIFT_DOWN = 8,
  HB_OT_MATH_CONSTANT_SUBSCRIPT_TOP_MAX = 9,
  HB_OT_MATH_CONSTANT_SUBSCRIPT_BASELINE_DROP_MIN = 10,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP = 11,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP_CRAMPED = 12,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MIN = 13,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_BASELINE_DROP_MAX = 14,
  HB_OT_MATH_CONSTANT_SUB_SUPERSCRIPT_GAP_MIN = 15,
  HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MAX_WITH_SUBSCRIPT = 16,
  HB_OT_MATH_CONSTANT_SPACE_AFTER_SCRIPT = 17,
  HB_OT_MATH_CONSTANT_UPPER_LIMIT_GAP_MIN = 18,
  HB_OT_MATH_CONSTANT_UPPER_LIMIT_BASELINE_RISE_MIN = 19,
  HB_OT_MATH_CONSTANT_LOWER_LIMIT_GAP_MIN = 20,
  HB_OT_MATH_CONSTANT_LOWER_LIMIT_BASELINE_DROP_MIN = 21,
  HB_OT_MATH_CONSTANT_STACK_TOP_SHIFT_UP = 22,
  HB_OT_MATH_CONSTANT_STACK_TOP_DISPLAY_STYLE_SHIFT_UP = 23,
  HB_OT_MATH_CONSTANT_STACK_BOTTOM_SHIFT_DOWN = 24,
  HB_OT_MATH_CONSTANT_STACK_BOTTOM_DISPLAY_STYLE_SHIFT_DOWN = 25,
  HB_OT_MATH_CONSTANT_STACK_GAP_MIN = 26,
  HB_OT_MATH_CONSTANT_STACK_DISPLAY_STYLE_GAP_MIN = 27,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_TOP_SHIFT_UP = 28,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_BOTTOM_SHIFT_DOWN = 29,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_ABOVE_MIN = 30,
  HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_BELOW_MIN = 31,
  HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_SHIFT_UP = 32,
  HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_DISPLAY_STYLE_SHIFT_UP = 33,
  HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_SHIFT_DOWN = 34,
  HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_DISPLAY_STYLE_SHIFT_DOWN = 35,
  HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_GAP_MIN = 36,
  HB_OT_MATH_CONSTANT_FRACTION_NUM_DISPLAY_STYLE_GAP_MIN = 37,
  HB_OT_MATH_CONSTANT_FRACTION_RULE_THICKNESS = 38,
  HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_GAP_MIN = 39,
  HB_OT_MATH_CONSTANT_FRACTION_DENOM_DISPLAY_STYLE_GAP_MIN = 40,
  HB_OT_MATH_CONSTANT_SKEWED_FRACTION_HORIZONTAL_GAP = 41,
  HB_OT_MATH_CONSTANT_SKEWED_FRACTION_VERTICAL_GAP = 42,
  HB_OT_MATH_CONSTANT_OVERBAR_VERTICAL_GAP = 43,
  HB_OT_MATH_CONSTANT_OVERBAR_RULE_THICKNESS = 44,
  HB_OT_MATH_CONSTANT_OVERBAR_EXTRA_ASCENDER = 45,
  HB_OT_MATH_CONSTANT_UNDERBAR_VERTICAL_GAP = 46,
  HB_OT_MATH_CONSTANT_UNDERBAR_RULE_THICKNESS = 47,
  HB_OT_MATH_CONSTANT_UNDERBAR_EXTRA_DESCENDER = 48,
  HB_OT_MATH_CONSTANT_RADICAL_VERTICAL_GAP = 49,
  HB_OT_MATH_CONSTANT_RADICAL_DISPLAY_STYLE_VERTICAL_GAP = 50,
  HB_OT_MATH_CONSTANT_RADICAL_RULE_THICKNESS = 51,
  HB_OT_MATH_CONSTANT_RADICAL_EXTRA_ASCENDER = 52,
  HB_OT_MATH_CONSTANT_RADICAL_KERN_BEFORE_DEGREE = 53,
  HB_OT_MATH_CONSTANT_RADICAL_KERN_AFTER_DEGREE = 54,
  HB_OT_MATH_CONSTANT_RADICAL_DEGREE_BOTTOM_RAISE_PERCENT = 55
} hb_ot_math_constant_t;
typedef enum {
  HB_OT_MATH_KERN_TOP_RIGHT = 0,
  HB_OT_MATH_KERN_TOP_LEFT = 1,
  HB_OT_MATH_KERN_BOTTOM_RIGHT = 2,
  HB_OT_MATH_KERN_BOTTOM_LEFT = 3
} hb_ot_math_kern_t;
typedef struct hb_ot_math_glyph_variant_t {
  hb_codepoint_t glyph;
  hb_position_t advance;
} hb_ot_math_glyph_variant_t;
typedef enum {
  HB_MATH_GLYPH_PART_FLAG_EXTENDER = 0x00000001u
} hb_ot_math_glyph_part_flags_t;
typedef struct hb_ot_math_glyph_part_t {
  hb_codepoint_t glyph;
  hb_position_t start_connector_length;
  hb_position_t end_connector_length;
  hb_position_t full_advance;
  hb_ot_math_glyph_part_flags_t flags;
} hb_ot_math_glyph_part_t;
hb_bool_t
hb_ot_math_has_data (hb_face_t *face);
hb_position_t
hb_ot_math_get_constant (hb_font_t *font,
    hb_ot_math_constant_t constant);
hb_position_t
hb_ot_math_get_glyph_italics_correction (hb_font_t *font,
      hb_codepoint_t glyph);
hb_position_t
hb_ot_math_get_glyph_top_accent_attachment (hb_font_t *font,
         hb_codepoint_t glyph);
hb_bool_t
hb_ot_math_is_glyph_extended_shape (hb_face_t *face,
        hb_codepoint_t glyph);
hb_position_t
hb_ot_math_get_glyph_kerning (hb_font_t *font,
         hb_codepoint_t glyph,
         hb_ot_math_kern_t kern,
         hb_position_t correction_height);
unsigned int
hb_ot_math_get_glyph_variants (hb_font_t *font,
          hb_codepoint_t glyph,
          hb_direction_t direction,
          unsigned int start_offset,
          unsigned int *variants_count,
          hb_ot_math_glyph_variant_t *variants );
hb_position_t
hb_ot_math_get_min_connector_overlap (hb_font_t *font,
          hb_direction_t direction);
unsigned int
hb_ot_math_get_glyph_assembly (hb_font_t *font,
          hb_codepoint_t glyph,
          hb_direction_t direction,
          unsigned int start_offset,
          unsigned int *parts_count,
          hb_ot_math_glyph_part_t *parts,
          hb_position_t *italics_correction );

// hb-ot-shape.h -------------------------------------------------------------

void
hb_ot_shape_glyphs_closure (hb_font_t *font,
       hb_buffer_t *buffer,
       const hb_feature_t *features,
       unsigned int num_features,
       hb_set_t *glyphs);
void
hb_ot_shape_plan_collect_lookups (hb_shape_plan_t *shape_plan,
      hb_tag_t table_tag,
      hb_set_t *lookup_indexes );

// hb-ot-var.h ---------------------------------------------------------------

typedef struct hb_ot_var_axis_t {
  hb_tag_t tag;
  unsigned int name_id;
  float min_value;
  float default_value;
  float max_value;
} hb_ot_var_axis_t;
hb_bool_t
hb_ot_var_has_data (hb_face_t *face);
enum {
	HB_OT_VAR_NO_AXIS_INDEX = 0xFFFFFFFFu,
};
unsigned int
hb_ot_var_get_axis_count (hb_face_t *face);
unsigned int
hb_ot_var_get_axes (hb_face_t *face,
      unsigned int start_offset,
      unsigned int *axes_count ,
      hb_ot_var_axis_t *axes_array );
hb_bool_t
hb_ot_var_find_axis (hb_face_t *face,
       hb_tag_t axis_tag,
       unsigned int *axis_index,
       hb_ot_var_axis_t *axis_info);
void
hb_ot_var_normalize_variations (hb_face_t *face,
    const hb_variation_t *variations,
    unsigned int variations_length,
    int *coords,
    unsigned int coords_length);
void
hb_ot_var_normalize_coords (hb_face_t *face,
       unsigned int coords_length,
       const float *design_coords,
       int *normalized_coords );
]]
