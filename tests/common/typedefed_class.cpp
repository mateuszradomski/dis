class c {
public:
    int field1;
    int field2;
};

typedef c another_class;

int t(another_class c) {
    return c.field1;
}

//class c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//class another_class { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
