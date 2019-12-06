// csrc/openssl/src/include/openssl/buffer.h
#define BUF_strdup(s) OPENSSL_strdup(s)
#define BUF_strndup(s,size) OPENSSL_strndup(s, size)
#define BUF_memdup(data,size) OPENSSL_memdup(data, size)
#define BUF_strlcpy(dst,src,size) OPENSSL_strlcpy(dst, src, size)
#define BUF_strlcat(dst,src,size) OPENSSL_strlcat(dst, src, size)
#define BUF_strnlen(str,maxlen) OPENSSL_strnlen(str, maxlen)
struct buf_mem_st {
    size_t length;
    char *data;
    size_t max;
    unsigned long flags;
};
enum {
	BUF_MEM_FLAG_SECURE  = 0x01,
};
BUF_MEM *BUF_MEM_new(void);
BUF_MEM *BUF_MEM_new_ex(unsigned long flags);
void BUF_MEM_free(BUF_MEM *a);
size_t BUF_MEM_grow(BUF_MEM *str, size_t len);
size_t BUF_MEM_grow_clean(BUF_MEM *str, size_t len);
void BUF_reverse(unsigned char *out, const unsigned char *in, size_t siz);

// csrc/openssl/src/include/openssl/buffererr.h
int ERR_load_BUF_strings(void);
enum {
	BUF_F_BUF_MEM_GROW   = 100,
	BUF_F_BUF_MEM_GROW_CLEAN = 105,
	BUF_F_BUF_MEM_NEW    = 101,
};
