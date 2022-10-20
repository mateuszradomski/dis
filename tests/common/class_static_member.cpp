class c {
public:
    int field1;
    static int skip_this_field;
    int field2;
};

int c::skip_this_field;

int t(c c) {
    return c.field1;
}

//class c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
