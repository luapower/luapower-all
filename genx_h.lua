--result of cpp genx.h from genx beta5
local ffi = require'ffi'
require'stdio_h'

ffi.cdef[[
typedef enum
{
  GENX_SUCCESS = 0,
  GENX_BAD_UTF8,
  GENX_NON_XML_CHARACTER,
  GENX_BAD_NAME,
  GENX_ALLOC_FAILED,
  GENX_BAD_NAMESPACE_NAME,
  GENX_INTERNAL_ERROR,
  GENX_DUPLICATE_PREFIX,
  GENX_SEQUENCE_ERROR,
  GENX_NO_START_TAG,
  GENX_IO_ERROR,
  GENX_MISSING_VALUE,
  GENX_MALFORMED_COMMENT,
  GENX_XML_PI_TARGET,
  GENX_MALFORMED_PI,
  GENX_DUPLICATE_ATTRIBUTE,
  GENX_ATTRIBUTE_IN_DEFAULT_NAMESPACE,
  GENX_DUPLICATE_NAMESPACE,
  GENX_BAD_DEFAULT_DECLARATION
} genxStatus;

typedef unsigned char * utf8;
typedef const unsigned char * constUtf8;

typedef struct genxWriter_rec_ genxWriter_rec, * genxWriter;
typedef struct genxNamespace_rec_ genxNamespace_rec, * genxNamespace;
typedef struct genxElement_rec_ genxElement_rec, * genxElement;
typedef struct genxAttribute_rec_ genxAttribute_rec, * genxAttribute;

genxWriter genxNew(
		void * (* alloc)(void * userData, int bytes),
		void (* dealloc)(void * userData, void * data),
		void * userData);
void genxDispose(genxWriter w);

void genxSetUserData(genxWriter w, void * userData);
void * genxGetUserData(genxWriter w);
void genxSetAlloc(genxWriter w, void * (* alloc)(void * userData, int bytes));
void genxSetDealloc(genxWriter w, void (* dealloc)(void * userData, void * data));
void * (* genxGetAlloc(genxWriter w))(void * userData, int bytes);
void (* genxGetDealloc(genxWriter w))(void * userData, void * data);

utf8 genxGetNamespacePrefix(genxNamespace ns);

genxNamespace genxDeclareNamespace(genxWriter w,
       constUtf8 uri, constUtf8 prefix,
       genxStatus * statusP);

genxElement genxDeclareElement(genxWriter w,
          genxNamespace ns, constUtf8 type,
          genxStatus * statusP);

genxAttribute genxDeclareAttribute(genxWriter w,
       genxNamespace ns,
       constUtf8 name, genxStatus * statusP);

genxStatus genxStartDocFile(genxWriter w, FILE * file);

typedef genxStatus (* send_callback)(void * userData, constUtf8 s);
typedef genxStatus (* sendBounded_callback)(void * userData, constUtf8 start, constUtf8 end);
typedef genxStatus (* flush_callback)(void * userData);

typedef struct {
	send_callback        send;
	sendBounded_callback sendBounded;
	flush_callback       flush;
} genxSender;

genxStatus genxStartDocSender(genxWriter w, genxSender * sender);
genxStatus genxEndDocument(genxWriter w);
genxStatus genxComment(genxWriter w, constUtf8 text);
genxStatus genxPI(genxWriter w, constUtf8 target, constUtf8 text);
genxStatus genxStartElementLiteral(genxWriter w, constUtf8 xmlns, constUtf8 type);
genxStatus genxStartElement(genxElement e);
genxStatus genxAddAttributeLiteral(genxWriter w, constUtf8 xmlns, constUtf8 name, constUtf8 value);
genxStatus genxAddAttribute(genxAttribute a, constUtf8 value);
genxStatus genxAddNamespace(genxNamespace ns, constUtf8 prefix); // NOTE: prefix changed from utf8 to constUtf8
genxStatus genxUnsetDefaultNamespace(genxWriter w);
genxStatus genxEndElement(genxWriter w);
genxStatus genxAddText(genxWriter w, constUtf8 start);
genxStatus genxAddCountedText(genxWriter w, constUtf8 start, int byteCount);
genxStatus genxAddBoundedText(genxWriter w, constUtf8 start, constUtf8 end);
genxStatus genxAddCharacter(genxWriter w, int c);
int genxNextUnicodeChar(constUtf8 * sp);
genxStatus genxCheckText(genxWriter w, constUtf8 s);
int genxCharClass(genxWriter w, int c);
int genxScrubText(genxWriter w, constUtf8 in, utf8 out);
char * genxGetErrorMessage(genxWriter w, genxStatus status);
char * genxLastErrorMessage(genxWriter w);
char * genxGetVersion();
]]
