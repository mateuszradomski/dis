union u {
    class c {
        public:
            int field1;
            int field2;
    };

    c c;
    int i;
    float f;
};

int t(u u) {
    return u.c.field1;
}

//union u { // size=8
//  class c { // size=8
//    int field1; // size=4, offset=0
//    int field2; // size=4, offset=4
//  } c;
//  int   i; // size=4, offset=0
//  float f; // size=4, offset=0
//};
//class c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
