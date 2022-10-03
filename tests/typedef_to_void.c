typedef void typedef_to_void;
struct s {
    int field1;
    int field2;
    typedef_to_void *ttv;
};

int t(struct s s) {
    return s.field1;
}

//struct s { // size=16
//  int              field1; // size=4, offset=0
//  int              field2; // size=4, offset=4
//  typedef_to_void *ttv;    // size=8, offset=8
//};
