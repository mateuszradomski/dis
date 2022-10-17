#include <stdint.h>

typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

struct stdint {
    s8 field1;
    s16 field2;
    s32 field3;
    s64 field4;
    u8 field5;
    u16 field6;
    u32 field7;
    u64 field8;
};

int t(struct stdint s) {
    return s.field1;
}

//struct stdint { // size=32
//  s8  field1; // size=1, offset=0
//  // HOLE => 1 bytes
//  s16 field2; // size=2, offset=2
//  s32 field3; // size=4, offset=4
//  s64 field4; // size=8, offset=8
//  u8  field5; // size=1, offset=16
//  // HOLE => 1 bytes
//  u16 field6; // size=2, offset=18
//  u32 field7; // size=4, offset=20
//  u64 field8; // size=8, offset=24
//};
