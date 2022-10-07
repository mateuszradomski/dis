union u {
    class c {
        public:
            int field1;
            int field2;
    } c;

    int i;
    float f;
};

int t(u u) {
    return u.c.field1;
}

//class c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//union u { // size=8
//  class c { // size=8
//    int field1; // size=4, offset=0
//    int field2; // size=4, offset=4
//  } c;
//  int   i; // size=4, offset=0
//  float f; // size=4, offset=0
//};
