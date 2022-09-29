#include <stdint.h>

struct stdint {
    int8_t field1;
    int16_t field2;
    int32_t field3;
    int64_t field4;
    uint8_t field5;
    uint16_t field6;
    uint32_t field7;
    uint64_t field8;
};

int t(struct stdint s) {
    return s.field1;
}

//struct stdint { // size=32
//  int8_t   field1; // size=1, offset=0
//  int16_t  field2; // size=2, offset=2
//  int32_t  field3; // size=4, offset=4
//  int64_t  field4; // size=8, offset=8
//  uint8_t  field5; // size=1, offset=16
//  uint16_t field6; // size=2, offset=18
//  uint32_t field7; // size=4, offset=20
//  uint64_t field8; // size=8, offset=24
//};
