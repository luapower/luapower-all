local ffi = require'ffi'
local x86 = ffi.arch == 'x86'
local x64 = ffi.arch == 'x64'

ffi.cdef([[
typedef union __attribute__((__packed__)) D_BYTE {
	uint8_t  b;
	uint8_t  u;
	int8_t   i;
} D_BYTE;

typedef union __attribute__((__packed__)) D_WORD {
	D_BYTE   bytes[2];
	struct { D_BYTE lo, hi; };
	uint8_t  b[2];
	uint16_t u;
	int16_t  i;
} D_WORD;

typedef union __attribute__((__packed__)) D_DWORD {
	D_BYTE   bytes[4];
	D_WORD   words[2];
	struct { D_WORD lo, hi; };
	uint8_t  b[4];
	uint32_t u;
	int32_t  i;
	float    f;
]]..(x86 and [[
	void*     p;
	D_BYTE*   bp;
	D_WORD*   wp;
	union D_DWORD* dp;
	union D_QWORD* qp;
]] or '')..[[
} D_DWORD;

typedef union __attribute__((__packed__)) D_QWORD {
	D_BYTE   bytes[8];
	D_WORD   words[4];
	D_DWORD  dwords[2];
	struct { D_DWORD lo, hi; };
	uint8_t  b[8];
	uint64_t u;
	int64_t  i;
	double   f;
]]..(x64 and [[
	void*     p;
	D_BYTE*   bp;
	D_WORD*   wp;
	D_DWORD*  dp;
	union D_QWORD* qp;
]]	or '')..[[
} D_QWORD;

typedef union __attribute__((__packed__)) D_DQWORD {
	D_BYTE   bytes[16];
	D_WORD   words[8];
	D_DWORD  dwords[4];
	D_QWORD  qwords[2];
	struct { D_QWORD lo, hi; };
	uint8_t  b[16];
} D_DQWORD;

typedef union __attribute__((__packed__)) D_TWORD {
	D_BYTE   bytes[10];
	struct __attribute__((__packed__)) {
		int64_t mantissa;
		struct {
			uint16_t exponent: 15;
			uint16_t sign: 1;
		};
	};
	uint8_t  b[10];
} D_TWORD;

typedef union __attribute__((__packed__)) D_EFLAGS {
	uint64_t val;
	struct {
		uint32_t CF: 1;  // 0
		uint32_t _1: 1;
		uint32_t PF: 1;  // 2
		uint32_t _2: 1;
		uint32_t AF: 1;  // 4
		uint32_t _3: 1;
		uint32_t ZF: 1;  // 6
		uint32_t SF: 1;  // 7
		uint32_t TF: 1;  // 8
		uint32_t IF: 1;  // 9
		uint32_t DF: 1;  // 10
		uint32_t OF: 1;  // 11
		uint32_t IOPL: 2; // 12-13
		uint32_t NT: 1;  // 14
		uint32_t _4: 1;
		uint32_t RF: 1;  // 16
		uint32_t VM: 1;  // 17
		uint32_t AC: 1;  // 18
		uint32_t VIF: 1; // 19
		uint32_t VIP: 1; // 20
		uint32_t ID: 1;  // 21
	};
} D_EFLAGS;

typedef union __attribute__((__packed__)) D_FCW {
	uint16_t val;
	struct {
		uint16_t IM: 1;  // 0
		uint16_t DM: 1;  // 1
		uint16_t ZM: 1;  // 2
		uint16_t OM: 1;  // 3
		uint16_t UM: 1;  // 4
		uint16_t PM: 1;  // 5
		uint16_t _1: 1;
		uint16_t IEM:1;  // 7
		uint16_t PC: 2;  // 8-9
		uint16_t RC: 2;  // 10-11
		uint16_t IC: 1;  // 12
	};
} D_FCW;

typedef union __attribute__((__packed__)) D_FSW {
	uint16_t val;
	struct {
		uint16_t I:  1; // 0
		uint16_t D:  1; // 1
		uint16_t Z:  1; // 2
		uint16_t O:  1; // 3
		uint16_t U:  1; // 4
		uint16_t P:  1; // 5
		uint16_t SF: 1; // 6
		uint16_t IR: 1; // 7
		uint16_t C0: 1; // 8
		uint16_t C1: 1; // 9
		uint16_t C2: 1; // 10
		uint16_t TOP:3; // 11-13
		uint16_t C3: 1; // 14
		uint16_t B:  1; // 15
	};
} D_FSW;

typedef union __attribute__((__packed__)) D_FTW { // TOS-independent order
	uint16_t val;
	struct {
		uint16_t FP7: 2;
		uint16_t FP6: 2;
		uint16_t FP5: 2;
		uint16_t FP4: 2;
		uint16_t FP3: 2;
		uint16_t FP2: 2;
		uint16_t FP1: 2;
		uint16_t FP0: 2;
	};
} D_FTW;

typedef union __attribute__((__packed__)) D_FTWX {
	uint8_t val;
	struct {
		uint8_t FP7: 1;
		uint8_t FP6: 1;
		uint8_t FP5: 1;
		uint8_t FP4: 1;
		uint8_t FP3: 1;
		uint8_t FP2: 1;
		uint8_t FP1: 1;
		uint8_t FP0: 1;
	};
} D_FTWX;

typedef struct __attribute__((__packed__)) D_FSTENV {
	D_FCW     FCW;
	uint16_t  _fstenv_1;
	D_FSW     FSW;
	uint16_t  _fstenv_2;
	D_FTW TW;
	uint16_t  _fstenv_3;
	uint32_t  FPU_IP;
	uint16_t  FPU_CS;
	uint16_t  _fstenv_4;
	uint32_t  FPU_OP;
	uint16_t  FPU_DS;
	uint16_t  _fstenv_5;
} D_FSTENV;

typedef struct D_MXCSR {
	uint32_t IE: 1; // 0
	uint32_t DE: 1; // 1
	uint32_t ZE: 1; // 2
	uint32_t OE: 1; // 3
	uint32_t UE: 1; // 4
	uint32_t PE: 1; // 5
	uint32_t DAZ:1; // 6
	uint32_t IM: 1; // 7
	uint32_t DM: 1; // 8
	uint32_t ZM: 1; // 9
	uint32_t OM: 1; // 10
	uint32_t UM: 1; // 11
	uint32_t PM: 1; // 12
	uint32_t RM: 2; // 13-14 (round mode)
	uint32_t FZ: 1; // 15
} D_MXCSR;

typedef struct __attribute__((__packed__)) D_FPRX {
	D_TWORD;       // 10 bytes
	uint8_t _1[6]; // 6 bytes padding
} D_FPRX;

typedef struct __attribute__((aligned (16))) D_FXSAVE {
	D_FCW      FCW;
	D_FSW      FSW;
	D_FTWX     FTWX;
	uint8_t    __1;
	uint16_t   FOP;
]]..(x86 and [[
	uint32_t   FIP;
	uint16_t   FCS;
	uint16_t   ___1;
	uint32_t   FDP;
	uint16_t   FDS;
	uint16_t   ___2;
]] or [[
	uint64_t   FIP;
	uint64_t   FDP;
]])..[[
	D_MXCSR    MXCSR;
	D_MXCSR    MXCSR_MASK;
	D_FPRX     FPR[8]; // in TOS-independent order
	D_DQWORD   XMM[16];
	uint8_t    __2[96];
} D_FXSAVE;

typedef struct D_CPUSTATE {
	union {
		D_QWORD GPR[16];
		struct { D_QWORD RAX, RCX, RDX, RBX, RSP, RBP, RSI, RDI, R8, R9, R10, R11, R12, R13, R14, R15; };
		struct { D_DWORD EAX, _1, ECX, _2, EDX, _3, EBX, _4, ESP, _5, EBP, _6, ESI, _7, EDI, _8; };
	};
	D_EFLAGS EFLAGS;
	D_FXSAVE;
} D_CPUSTATE;
]])

assert(ffi.sizeof('D_BYTE') == 1)
assert(ffi.sizeof('D_WORD') == 2)
assert(ffi.sizeof('D_DWORD') == 4)
assert(ffi.sizeof('D_QWORD') == 8)
assert(ffi.sizeof('D_TWORD') == 10)
assert(ffi.sizeof('D_EFLAGS') == 8)
assert(ffi.sizeof('D_FSTENV') == 28)
assert(ffi.sizeof('D_FPRX') == 16)
assert(ffi.sizeof('D_FXSAVE') == 512)

