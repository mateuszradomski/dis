class c1 {
    public:
    class c2 {
        public:
            int field1;
            int field2;
    };

    c2 c2;
    int i;
    float f;
};

int t(c1 c) {
    return c.c2.field1;
}

//class c2 { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//class c1 { // size=16
//  class c2 { // size=8
//    int field1; // size=4, offset=0
//    int field2; // size=4, offset=4
//  } c2;
//  int   i; // size=4, offset=8
//  float f; // size=4, offset=12
//};
