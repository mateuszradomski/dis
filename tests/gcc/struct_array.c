struct nested_struct {
    unsigned long long length;
    void *data;
};

struct array {
    struct nested_struct field1[4];
};

int t(struct array s) {
    return s.field1[0].length;
}

//struct nested_struct { // size=16
//  long long unsigned int length; // size=8, offset=0
//  void *                 data;   // size=8, offset=8
//};
//struct array { // size=64
//  nested_struct field1[4]; // size=64, offset=0
//};
