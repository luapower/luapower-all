
local ffi = require'ffi'
local shl = bit.lshift
local bor = bit.bor
require'winapi.types'
local C = ffi.load'crypt32'

ffi.cdef[[

// Cert store ----------------------------------------------------------------

typedef void *HCERTSTORE;
typedef ULONG_PTR HCRYPTPROV_LEGACY;

HCERTSTORE CertOpenStore(
  LPCSTR            lpszStoreProvider,
  DWORD             dwEncodingType,
  HCRYPTPROV_LEGACY hCryptProv,
  DWORD             dwFlags,
  const void        *pvPara
);

typedef struct _CERT_CONTEXT CERT_CONTEXT, *PCERT_CONTEXT;
typedef const CERT_CONTEXT *PCCERT_CONTEXT;

PCCERT_CONTEXT CertFindCertificateInStore(
  HCERTSTORE     hCertStore,
  DWORD          dwCertEncodingType,
  DWORD          dwFindFlags,
  DWORD          dwFindType,
  const void     *pvFindPara,
  PCCERT_CONTEXT pPrevCertContext
);

// SCHANNEL ------------------------------------------------------------------

typedef LONG SECURITY_STATUS;

typedef PVOID SEC_GET_KEY_FN;

typedef struct _SecHandle
{
	ULONG_PTR dwLower;
	ULONG_PTR dwUpper;
} SecHandle, *PSecHandle;

typedef SecHandle CredHandle;
typedef PSecHandle PCredHandle;

typedef unsigned __int64 QWORD;
typedef QWORD SECURITY_INTEGER, *PSECURITY_INTEGER;

typedef SECURITY_INTEGER *PTimeStamp;

SECURITY_STATUS __stdcall AcquireCredentialsHandleA(
  LPSTR           pszPrincipal,
  LPSTR           pszPackage,
  unsigned long   fCredentialUse,
  void           *pvLogonId,
  void           *pAuthData,
  SEC_GET_KEY_FN  pGetKeyFn,
  void           *pvGetKeyArgument,
  PCredHandle     phCredential,
  PTimeStamp      ptsExpiry
);

BOOL CertCloseStore(
	HCERTSTORE hCertStore,
	DWORD dwFlags
);

BOOL CertFreeCertificateContext(
	PCCERT_CONTEXT pCertContext
);

]]

local CERT_STORE_PROV_SYSTEM_A = 9

local X509_ASN_ENCODING = 0x00000001

local CERT_COMPARE_NAME_STR_A = 7

local CERT_INFO_SUBJECT_FLAG = 7

local CERT_SYSTEM_STORE_CURRENT_USER_ID               = 1
local CERT_SYSTEM_STORE_LOCAL_MACHINE_ID              = 2
local CERT_SYSTEM_STORE_CURRENT_SERVICE_ID            = 4
local CERT_SYSTEM_STORE_SERVICES_ID                   = 5
local CERT_SYSTEM_STORE_USERS_ID                      = 6
local CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY_ID  = 7
local CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY_ID = 8
local CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE_ID   = 9

if not ... then


	local cs = 'HCERTSTORE[1]'
	local cc = 'PCCERT_CONTEXT[1]'

	cs = C.CertOpenStore(
		ffi.cast('LPCSTR', CERT_STORE_PROV_SYSTEM_A),
		X509_ASN_ENCODING,
		0, shl(CERT_SYSTEM_STORE_LOCAL_MACHINE_ID, 16),
		'MY')

	assert(cs ~= nil)

	local cc = C.CertFindCertificateInStore(cs,
		X509_ASN_ENCODING, 0,
		bor(shl(CERT_COMPARE_NAME_STR_A, 16), CERT_INFO_SUBJECT_FLAG),
		'google.com',
		nil
	)

	assert(cc ~= nil)

	C.CertFreeCertificateContext(cc)
	C.CertCloseStore(cs, 0)

end
