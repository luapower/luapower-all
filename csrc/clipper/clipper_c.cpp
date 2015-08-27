//Clipper C wrapper by Cosmin Apreutesei (public domain)
#include <stdint.h>
#include "clipper.cpp"

using namespace ClipperLib;

#ifdef __MINGW32__
	#define export extern "C" __declspec (dllexport)
#else
	#define export extern "C" __attribute__ ((visibility ("default")))
#endif

// clipper_polygon class

export Polygon* clipper_polygon_create(int n) {
	try {
		return new Polygon(n);
	} catch(...) {
		return 0;
	}
}

export void clipper_polygon_free(Polygon* poly) {
	delete poly;
}

export int clipper_polygon_size(Polygon* poly) {
	return poly->size();
}

export IntPoint* clipper_polygon_get(Polygon* poly, int i) {
	return &((*poly)[i]);
}

export int clipper_polygon_add(Polygon* poly, int64_t x, int64_t y) {
	try {
		poly->push_back(IntPoint(x, y));
		return 0;
	} catch(...) {
		return 1;
	}
}

export Polygons* clipper_polygon_simplify(Polygon* poly, PolyFillType fill_type) {
	try {
		Polygons* out = new Polygons();
		SimplifyPolygon(*poly, *out, PolyFillType(fill_type));
		return out;
	} catch(...) {
		return 0;
	}
}

export Polygon* clipper_polygon_clean(Polygon* poly, double distance) {
	try {
		Polygon* out = new Polygon();
		CleanPolygon(*poly, *out, distance);
		return out;
	} catch(...) {
		return 0;
	}
}

export void clipper_polygon_reverse(Polygon* poly) {
	ReversePolygon(*poly);
}

export int clipper_polygon_orientation(Polygon* poly) {
	return Orientation(*poly);
}

export double clipper_polygon_area(Polygon* poly) {
	return Area(*poly);
}

// clipper_polygons class

export Polygons* clipper_polygons_create(int n) {
	try {
		return new Polygons(n);
	} catch(...) {
		return 0;
	}
}

export void clipper_polygons_free(Polygons* poly) {
	delete poly;
}

export int clipper_polygons_size(Polygons* poly) {
	return poly->size();
}

export Polygon* clipper_polygons_get(Polygons* poly, int i) {
	return &((*poly)[i]);
}

export void clipper_polygons_set(Polygons* poly, int i, Polygon* e) {
	(*poly)[i] = *e;
}

export int clipper_polygons_add(Polygons* poly, Polygon* e) {
	try {
		poly->push_back(*e);
		return 0;
	} catch(...) {
		return 1;
	}
}

export Polygons* clipper_polygons_simplify(Polygons* poly, PolyFillType fill_type) {
	try {
		Polygons* out = new Polygons();
		SimplifyPolygons(*poly, *out, PolyFillType(fill_type));
		return out;
	} catch(...) {
		return 0;
	}
}

export Polygons* clipper_polygons_clean(Polygons* poly, double distance) {
	try {
		Polygons* out = new Polygons(poly->size());
		CleanPolygons(*poly, *out, distance);
		return out;
	} catch(...) {
		return 0;
	}
}

export void clipper_polygons_reverse(Polygons* poly) {
	ReversePolygons(*poly);
}

export Polygons* clipper_polygons_offset(Polygons* poly, double delta, JoinType jointype, double miter_limit) {
	try {
		Polygons* out = new Polygons();
		OffsetPolygons(*poly, *out, delta, JoinType(jointype), miter_limit, false);
		return out;
	} catch(...) {
		return 0;
	}
}

// clipper class

export Clipper* clipper_create() {
	try {
		return new Clipper();
	} catch(...) {
		return 0;
	}
}

export void clipper_free(Clipper* clipper) {
	delete clipper;
}

export int clipper_add_polygon(Clipper* clipper, Polygon* poly, PolyType poly_type) {
	return clipper->AddPolygon(*poly, PolyType(poly_type));
}

export int clipper_add_polygons(Clipper* clipper, Polygons* poly, PolyType poly_type) {
	return clipper->AddPolygons(*poly, PolyType(poly_type));
}

export void clipper_get_bounds(Clipper* clipper, IntRect* out) {
	*out = clipper->GetBounds();
}

export Polygons* clipper_execute(Clipper* clipper, ClipType clipType,
									PolyFillType subjFillType,
									PolyFillType clipFillType) {
	try {
		Polygons* solution = new Polygons();
		clipper->Execute(ClipType(clipType), *solution,
											PolyFillType(subjFillType),
											PolyFillType(clipFillType));
		return solution;
	} catch(...) {
		return 0;
	}
}

export void clipper_clear(Clipper* clipper) {
	clipper->Clear();
}

export int clipper_get_reverse_solution(Clipper* clipper) {
	return clipper->ReverseSolution();
}

export void clipper_set_reverse_solution(Clipper* clipper, int reverse) {
	clipper->ReverseSolution(reverse);
}

