struct inner_struct {
    int inner_field1;
    char inner_field2;
};

struct outer_struct {
    struct inner_struct field_ins1;
    unsigned int field2;
};

int t(struct outer_struct s) {
    return s.field2;
}

//struct inner_struct { // size=8
//  int  inner_field1; // size=4, offset=0
//  char inner_field2; // size=1, offset=4
//};
//struct outer_struct { // size=12
//  inner_struct field_ins1; // size=8, offset=0
//  unsigned int field2;     // size=4, offset=8
//};
