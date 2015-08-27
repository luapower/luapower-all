local ffi = require'ffi'
local hb = ffi.load'harfbuzz'
require'harfbuzz_h'
local ft = require'freetype'
local cairo = require'cairo'
require'cairo_ft_h'

local ft_library = ft.FT_Init_FreeType()
local ft_face = ft_library:new_face"media/fonts/DejaVuSerif.ttf"
local hb_ft_font = hb.hb_ft_font_create(ft_face, nil)
local hb_ft_face = hb.hb_ft_face_create(ft_face, nil)

  static const hb_tag_t CFFTag		= HB_TAG ('O','T','T','O'); /* OpenType with Postscript outlines */
  static const hb_tag_t TrueTypeTag	= HB_TAG ( 0 , 1 , 0 , 0 ); /* OpenType with TrueType outlines */
  static const hb_tag_t TTCTag		= HB_TAG ('t','t','c','f'); /* TrueType Collection */
  static const hb_tag_t TrueTag		= HB_TAG ('t','r','u','e'); /* Obsolete Apple TrueType */
  static const hb_tag_t Typ1Tag		= HB_TAG ('t','y','p','1'); /* Obsolete Apple Type1 font in SFNT container */

  inline hb_tag_t get_tag (void) const { return u.tag; }

  inline unsigned int get_face_count (void) const
  {
    switch (u.tag) {
    case CFFTag:	/* All the non-collection tags */
    case TrueTag:
    case Typ1Tag:
    case TrueTypeTag:	return 1;
    case TTCTag:	return u.ttcHeader.get_face_count ();
    default:		return 0;
    }
  }

  inline const OpenTypeFontFace& get_face (unsigned int i) const
  {
    switch (u.tag) {
    /* Note: for non-collection SFNT data we ignore index.  This is because
     * Apple dfont container is a container of SFNT's.  So each SFNT is a
     * non-TTC, but the index is more than zero. */
    case CFFTag:	/* All the non-collection tags */
    case TrueTag:
    case Typ1Tag:
    case TrueTypeTag:	return u.fontFace;
    case TTCTag:	return u.ttcHeader.get_face (i);
    default:		return Null(OpenTypeFontFace);
    }
  }

  inline bool sanitize (hb_sanitize_context_t *c) {
    TRACE_SANITIZE (this);
    if (unlikely (!u.tag.sanitize (c))) return TRACE_RETURN (false);
    switch (u.tag) {
    case CFFTag:	/* All the non-collection tags */
    case TrueTag:
    case Typ1Tag:
    case TrueTypeTag:	return TRACE_RETURN (u.fontFace.sanitize (c));
    case TTCTag:	return TRACE_RETURN (u.ttcHeader.sanitize (c));
    default:		return TRACE_RETURN (true);
    }
  }

  protected:
  union {
  Tag			tag;		/* 4-byte identifier. */
  OpenTypeFontFace	fontFace;
  TTCHeader		ttcHeader;
  } u;
  public:
  DEFINE_SIZE_UNION (4, tag);
};







  const OpenTypeFontFile &ot = *CastP<OpenTypeFontFile> (font_data);

  switch (ot.get_tag ()) {
  case OpenTypeFontFile::TrueTypeTag:
    printf ("OpenType font with TrueType outlines\n");
    break;
  case OpenTypeFontFile::CFFTag:
    printf ("OpenType font with CFF (Type1) outlines\n");
    break;
  case OpenTypeFontFile::TTCTag:
    printf ("TrueType Collection of OpenType fonts\n");
    break;
  case OpenTypeFontFile::TrueTag:
    printf ("Obsolete Apple TrueType font\n");
    break;
  case OpenTypeFontFile::Typ1Tag:
    printf ("Obsolete Apple Type1 font in SFNT container\n");
    break;
  default:
    printf ("Unknown font format\n");
    break;
  }

  int num_fonts = ot.get_face_count ();
  printf ("%d font(s) found in file\n", num_fonts);
  for (int n_font = 0; n_font < num_fonts; n_font++) {
    const OpenTypeFontFace &font = ot.get_face (n_font);
    printf ("Font %d of %d:\n", n_font, num_fonts);

    int num_tables = font.get_table_count ();
    printf ("  %d table(s) found in font\n", num_tables);
    for (int n_table = 0; n_table < num_tables; n_table++) {
      const OpenTypeTable &table = font.get_table (n_table);
      printf ("  Table %2d of %2d: %.4s (0x%08x+0x%08x)\n", n_table, num_tables,
	      (const char *)table.tag,
	      (unsigned int) table.offset,
	      (unsigned int) table.length);

      switch (table.tag) {

      case GSUBGPOS::GSUBTag:
      case GSUBGPOS::GPOSTag:
	{

	const GSUBGPOS &g = *CastP<GSUBGPOS> (font_data + table.offset);

	int num_scripts = g.get_script_count ();
	printf ("    %d script(s) found in table\n", num_scripts);
	for (int n_script = 0; n_script < num_scripts; n_script++) {
	  const Script &script = g.get_script (n_script);
	  printf ("    Script %2d of %2d: %.4s\n", n_script, num_scripts,
	          (const char *)g.get_script_tag(n_script));

	  if (!script.has_default_lang_sys())
	    printf ("      No default language system\n");
	  int num_langsys = script.get_lang_sys_count ();
	  printf ("      %d language system(s) found in script\n", num_langsys);
	  for (int n_langsys = script.has_default_lang_sys() ? -1 : 0; n_langsys < num_langsys; n_langsys++) {
	    const LangSys &langsys = n_langsys == -1
				   ? script.get_default_lang_sys ()
				   : script.get_lang_sys (n_langsys);
	    if (n_langsys == -1)
	      printf ("      Default Language System\n");
	    else
	      printf ("      Language System %2d of %2d: %.4s\n", n_langsys, num_langsys,
		      (const char *)script.get_lang_sys_tag (n_langsys));
	    if (langsys.get_required_feature_index () == Index::NOT_FOUND_INDEX)
	      printf ("        No required feature\n");

	    int num_features = langsys.get_feature_count ();
	    printf ("        %d feature(s) found in language system\n", num_features);
	    for (int n_feature = 0; n_feature < num_features; n_feature++) {
	      printf ("        Feature index %2d of %2d: %d\n", n_feature, num_features,
	              langsys.get_feature_index (n_feature));
	    }
	  }
	}

	int num_features = g.get_feature_count ();
	printf ("    %d feature(s) found in table\n", num_features);
	for (int n_feature = 0; n_feature < num_features; n_feature++) {
	  const Feature &feature = g.get_feature (n_feature);
	  printf ("    Feature %2d of %2d: %.4s; %d lookup(s)\n", n_feature, num_features,
	          (const char *)g.get_feature_tag(n_feature),
		  feature.get_lookup_count());

	  int num_lookups = feature.get_lookup_count ();
	  printf ("        %d lookup(s) found in feature\n", num_lookups);
	  for (int n_lookup = 0; n_lookup < num_lookups; n_lookup++) {
	    printf ("        Lookup index %2d of %2d: %d\n", n_lookup, num_lookups,
	            feature.get_lookup_index (n_lookup));
	  }
	}

	int num_lookups = g.get_lookup_count ();
	printf ("    %d lookup(s) found in table\n", num_lookups);
	for (int n_lookup = 0; n_lookup < num_lookups; n_lookup++) {
	  const Lookup &lookup = g.get_lookup (n_lookup);
	  printf ("    Lookup %2d of %2d: type %d, props 0x%04X\n", n_lookup, num_lookups,
	          lookup.get_type(), lookup.get_props());
	}

	}
	break;

      case GDEF::Tag:
	{

	const GDEF &gdef = *CastP<GDEF> (font_data + table.offset);

	printf ("    Has %sglyph classes\n",
		  gdef.has_glyph_classes () ? "" : "no ");
	printf ("    Has %smark attachment types\n",
		  gdef.has_mark_attachment_types () ? "" : "no ");
	printf ("    Has %sattach points\n",
		  gdef.has_attach_points () ? "" : "no ");
	printf ("    Has %slig carets\n",
		  gdef.has_lig_carets () ? "" : "no ");
	printf ("    Has %smark sets\n",
		  gdef.has_mark_sets () ? "" : "no ");
	break;
	}
      }
    }
  }

  return 0;
}


