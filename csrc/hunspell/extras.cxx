// extra hunspell API exposures
#include "hunspell.hxx"
#include "hunspell.h"

#ifdef __cplusplus
extern "C" {
#endif

LIBHUNSPELL_DLL_EXPORTED int Hunspell_add_dic(Hunhandle *pHunspell, const char * dpath, const char * key) {
	return ((Hunspell*)pHunspell)->add_dic(dpath, key);
}

#ifdef __cplusplus
}
#endif
