//go@ gcc -std=c11 -O3 lx_test.c lx.c -o lx_test.exe

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include "lx.h"

clock_t test(const char* file, double* n, double* l) {
	LX_State* ls;
	FILE* f;
	clock_t t0;

	f = fopen(file, "rb");
	assert(f);

	ls = lx_state_create_for_file(f);

	#define puts(x)

	t0 = clock();

	while (1) {
		LX_Token tok = lx_next(ls); (*n)++;
		switch (tok) {
			case TK_EOF:
				goto endloop;
			case TK_ERROR: {
				int err = lx_error(ls);
				printf("ERROR: ", err);
				goto endloop;
			}
			case TK_NUMBER: {
				int fmt = lx_number_type(ls);
				switch (fmt) {
					case STRSCAN_NUM: {
						double d = lx_double_value(ls);
						//printf("%f ", d);
						break;
					}
					case STRSCAN_IMAG:
						printf("imag NYI ");
						break;
					case STRSCAN_INT: {
						int i = lx_int32_value(ls);
						//printf("%d ", i);
						break;
					}
					case STRSCAN_U64: {
						uint64_t u = lx_uint64_value(ls);
						printf("%d ", u);
						break;
					}
					default:
						assert(0);
				}
				break;
			}
			case TK_NAME:
			case TK_STRING:
			case TK_LABEL: {
				int len;
				char* s = lx_string_value(ls, &len);
				//printf("%.*s ", len, s);
				break;
			}
			case TK_EQ:     puts("= "  ); break;
			case TK_LE:     puts("<= " ); break;
			case TK_GE:     puts(">= " ); break;
			case TK_NE:     puts("~= " ); break;
			case TK_DOTS:   puts("... "); break;
			case TK_CONCAT: puts(".. " ); break;
			//default:
				//putchar(tok);
				//putchar(' ');
		}
	} endloop:

	*l = *l + lx_line_number(ls);
	t0 = clock() - t0;

	lx_state_free(ls);

	fclose(f);

	return t0;
}

void main(void) {
	double d = 0;
	double n = 0;
	double l = 0;
	for (int i = 0; i < 1000; i++) {
		d += test("../../ui.lua", &n, &l);
	}
	d = d / 1000;
	printf("%.1fs %.1f Mtokens/s %.1f Mlines/s\n",
		d, n / d / 1e6, l / d / 1e6);
	fflush(stdout);
}
