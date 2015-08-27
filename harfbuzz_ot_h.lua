--hb-ot.h from harfbuzz HEAD from May 24, 2013
local ffi = require'ffi'
require'harfbuzz_h'

ffi.cdef[[
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
      hb_set_t *glyphs);
unsigned int
hb_ot_layout_get_attach_points (hb_face_t *face,
    hb_codepoint_t glyph,
    unsigned int start_offset,
    unsigned int *point_count,
    unsigned int *point_array);
unsigned int
hb_ot_layout_get_ligature_carets (hb_font_t *font,
      hb_direction_t direction,
      hb_codepoint_t glyph,
      unsigned int start_offset,
      unsigned int *caret_count,
      hb_position_t *caret_array);
unsigned int
hb_ot_layout_table_get_script_tags (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int start_offset,
        unsigned int *script_count,
        hb_tag_t *script_tags);
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
         unsigned int *feature_count,
         hb_tag_t *feature_tags);
unsigned int
hb_ot_layout_script_get_language_tags (hb_face_t *face,
           hb_tag_t table_tag,
           unsigned int script_index,
           unsigned int start_offset,
           unsigned int *language_count,
           hb_tag_t *language_tags);
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
unsigned int
hb_ot_layout_language_get_feature_indexes (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int script_index,
        unsigned int language_index,
        unsigned int start_offset,
        unsigned int *feature_count,
        unsigned int *feature_indexes);
unsigned int
hb_ot_layout_language_get_feature_tags (hb_face_t *face,
     hb_tag_t table_tag,
     unsigned int script_index,
     unsigned int language_index,
     unsigned int start_offset,
     unsigned int *feature_count,
     hb_tag_t *feature_tags);
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
      unsigned int *lookup_indexes);
void
hb_ot_layout_collect_lookups (hb_face_t *face,
         hb_tag_t table_tag,
         const hb_tag_t *scripts,
         const hb_tag_t *languages,
         const hb_tag_t *features,
         hb_set_t *lookup_indexes);
void
hb_ot_shape_plan_collect_lookups (hb_shape_plan_t *shape_plan,
      hb_tag_t table_tag,
      hb_set_t *lookup_indexes);
void
hb_ot_layout_lookup_collect_glyphs (hb_face_t *face,
        hb_tag_t table_tag,
        unsigned int lookup_index,
        hb_set_t *glyphs_before,
        hb_set_t *glyphs_input,
        hb_set_t *glyphs_after,
        hb_set_t *glyphs_output);
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
            hb_set_t *glyphs);
hb_bool_t
hb_ot_layout_has_positioning (hb_face_t *face);
hb_bool_t
hb_ot_layout_get_size_params (hb_face_t *face,
         unsigned int *design_size,
         unsigned int *subfamily_id,
         unsigned int *subfamily_name_id,
         unsigned int *range_start,
         unsigned int *range_end);
void
hb_ot_shape_glyphs_closure (hb_font_t *font,
       hb_buffer_t *buffer,
       const hb_feature_t *features,
       unsigned int num_features,
       hb_set_t *glyphs);
]]
