#include <stdint.h>

typedef void *ZeroMarker[0];
typedef uint64_t ZeroMarker64[0];

struct zero_sized {
    int count;
    float dynamic_levels[0];
    ZeroMarker z1;
    ZeroMarker64 z2;
};

int t(struct zero_sized s) {
    return s.count;
}

//struct zero_sized { // size=8
//  int          count;             // size=4, offset=0
//  float        dynamic_levels[0]; // size=0, offset=4
//  ZeroMarker   z1;                // size=0, offset=8
//  ZeroMarker64 z2;                // size=0, offset=8
//};
