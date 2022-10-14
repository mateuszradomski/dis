typedef enum enumerated_values {
    one,
    two,
} enumerated_values;

typedef struct {
    enumerated_values field1;
    int count;
    enumerated_values field3;
} struct_with_enum;

int t(struct_with_enum s) {
    return s.count;
}

//struct struct_with_enum { // size=12
//  enumerated_values field1; // size=4, offset=0
//  int               count;  // size=4, offset=4
//  enumerated_values field3; // size=4, offset=8
//};
