local ffi = require'ffi'
local C = ffi.load'clipper'

if not ... then require'clipper_demo'; return end

ffi.cdef[[
typedef struct clipper_point_st { int64_t x, y; } clipper_point;
typedef struct clipper_rect_st { int64_t x1, y1, x2, y2; } clipper_rect;

typedef enum {
	clipper_ctIntersection,
	clipper_ctUnion,
	clipper_ctDifference,
	clipper_ctXor
} clipper_ClipType;

typedef enum {
	clipper_ptSubject,
	clipper_ptClip
} clipper_PolyType;

typedef enum {
	clipper_pftEvenOdd,
	clipper_pftNonZero,
	clipper_pftPositive,
	clipper_pftNegative
} clipper_PolyFillType;

typedef enum {
	clipper_jtSquare,
	clipper_jtRound,
	clipper_jtMiter
} clipper_JoinType;

typedef struct clipper_Polygon clipper_polygon;
typedef struct clipper_Polygons clipper_polygons;
typedef struct clipper_Clipper clipper;

clipper_polygon*  clipper_polygon_create(int);
void              clipper_polygon_free        (clipper_polygon*);
int               clipper_polygon_size        (clipper_polygon*);
clipper_point*    clipper_polygon_get         (clipper_polygon*, int);
int               clipper_polygon_add         (clipper_polygon*, int64_t x, int64_t y);
clipper_polygons* clipper_polygon_simplify    (clipper_polygon*, clipper_PolyFillType);
clipper_polygon*  clipper_polygon_clean       (clipper_polygon*, double);
void              clipper_polygon_reverse     (clipper_polygon*);
int               clipper_polygon_orientation (clipper_polygon*);
double            clipper_polygon_area        (clipper_polygon*);

clipper_polygons* clipper_polygons_create(int n);
void              clipper_polygons_free        (clipper_polygons*);
int               clipper_polygons_size        (clipper_polygons*);
clipper_polygon*  clipper_polygons_get         (clipper_polygons*, int);
void              clipper_polygons_set         (clipper_polygons*, int, clipper_polygon*);
int               clipper_polygons_add         (clipper_polygons*, clipper_polygon*);
clipper_polygons* clipper_polygons_simplify    (clipper_polygons*, clipper_PolyFillType);
clipper_polygons* clipper_polygons_clean       (clipper_polygons*, double);
void              clipper_polygons_reverse     (clipper_polygons*);
clipper_polygons* clipper_polygons_offset      (clipper_polygons*, double, clipper_JoinType, double);

clipper*          clipper_create();
void              clipper_free         (clipper*);
int               clipper_add_polygon  (clipper*, clipper_polygon*, clipper_PolyType);
int               clipper_add_polygons (clipper*, clipper_polygons*, clipper_PolyType);
void              clipper_get_bounds   (clipper*, clipper_rect*);
clipper_polygons* clipper_execute      (clipper*, clipper_ClipType,
																	clipper_PolyFillType,
																	clipper_PolyFillType);
void              clipper_clear        (clipper*);
int               clipper_get_reverse_solution (clipper*);
void              clipper_set_reverse_solution (clipper*, int);
]]

local fill_types = {
	even_odd = C.clipper_pftEvenOdd,
	non_zero = C.clipper_pftNonZero,
	positive = C.clipper_pftPositive,
	negative = C.clipper_pftNegative,
}

local join_types = {
	square = C.clipper_jtSquare,
	round  = C.clipper_jtRound,
	miter  = C.clipper_jtMiter,
}

local clip_types = {
	intersection = C.clipper_ctIntersection,
	union        = C.clipper_ctUnion,
	difference   = C.clipper_ctDifference,
	xor          = C.clipper_ctXor
}

local polygon_type = ffi.typeof'clipper_polygon*'
local function is_polygon(poly)
	return ffi.istype(polygon_type, poly)
end

local polygon = {} --polygon methods

function polygon.new(n)
	return ffi.gc(C.clipper_polygon_create(n or 0), C.clipper_polygon_free)
end

function polygon:free()
	C.clipper_polygon_free(self)
	ffi.gc(self, nil)
end

polygon.size = C.clipper_polygon_size

function polygon:get(i)
	return C.clipper_polygon_get(self, i-1)
end

function polygon:add(x, y)
	assert(C.clipper_polygon_add(self, x, y) == 0, 'out of memory')
end

function polygon:simplify(fill_type)
	local out = C.clipper_polygon_simplify(self, fill_types[fill_type or 'even_odd'])
	return ffi.gc(out, C.clipper_polygons_free)
end

function polygon:clean(d)
	local out = C.clipper_polygon_clean(self, d or 1.415)
	return ffi.gc(out, C.clipper_polygon_free)
end

polygon.reverse = C.clipper_polygon_reverse

function polygon:orientation()
	return C.clipper_polygon_orientation(self) == 1
end

polygon.area = C.clipper_polygon_area

local polygons = {} --polygons methods

function polygons.new(...)
	if is_polygon(...) then
		local n = select('#',...)
		local out = ffi.gc(C.clipper_polygons_create(n), C.clipper_polygons_free)
		for i=1,n do
			out:set(i, select(i,...))
		end
		return out
	else
		return ffi.gc(C.clipper_polygons_create(... or 0), C.clipper_polygons_free)
	end
end

function polygons:free()
	C.clipper_polygons_free(self)
	ffi.gc(self, nil)
end

polygons.size = C.clipper_polygons_size

function polygons:get(i)
	return C.clipper_polygons_get(self, i-1)
end

function polygons:set(i, poly)
	return C.clipper_polygons_set(self, i-1, poly)
end

function polygons:add(poly)
	assert(C.clipper_polygons_add(self, poly) == 0, 'out of memory')
end

function polygons:simplify(fill_type)
	local out = C.clipper_polygons_simplify(self, fill_types[fill_type or 'even_odd'])
	return ffi.gc(out, C.clipper_polygons_free)
end

function polygons:clean(d)
	local out = C.clipper_polygons_clean(self, d or 1.415)
	return ffi.gc(out, C.clipper_polygons_free)
end

polygons.reverse = C.clipper_polygons_reverse

function polygons:offset(delta, join_type, limit)
	local out = C.clipper_polygons_offset(self, delta, join_types[join_type or 'square'], limit or 0)
	return ffi.gc(out, C.clipper_polygons_free)
end

local clipper = {} --clipper methods

function clipper.new()
	return ffi.gc(C.clipper_create(), C.clipper_free)
end

function clipper:free()
	C.clipper_free(self)
	ffi.gc(self, nil)
end

local function clipper_add(self, poly, where_flag)
	if is_polygon(poly) then
		assert(C.clipper_add_polygon(self, poly, where_flag) ~= 0)
	else
		assert(C.clipper_add_polygons(self, poly, where_flag) ~= 0)
	end
end

function clipper:add_subject(poly) clipper_add(self, poly, C.clipper_ptSubject) end
function clipper:add_clip(poly) clipper_add(self, poly, C.clipper_ptClip) end

function clipper:get_bounds(r)
	local r = r or ffi.new'clipper_rect'
	C.clipper_get_bounds(self, r)
	return r.x1, r.y1, r.x2, r.y2
end

function clipper:execute(clip_type, subj_fill_type, clip_fill_type, reverse)
	C.clipper_set_reverse_solution(self, reverse and 1 or 0)
	local out = C.clipper_execute(self,
						clip_types[clip_type],
						fill_types[subj_fill_type or 'even_odd'],
						fill_types[clip_fill_type or 'even_odd'])
	return ffi.gc(out, C.clipper_polygons_free)
end

clipper.clear = C.clipper_clear

ffi.metatype('clipper_polygon', {__index = polygon})
ffi.metatype('clipper_polygons', {__index = polygons})
ffi.metatype('clipper', {__index = clipper})

return {
	new = clipper.new,
	polygon = polygon.new,
	polygons = polygons.new,
	C = C,
}

