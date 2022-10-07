struct s {
    class c {
        public:
            int field1;
            int field2;
    } c;

    int i;
    float f;
};

int t(s s) {
    return s.c.field1;
}

//class c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//struct s { // size=16
//  class c { // size=8
//    int field1; // size=4, offset=0
//    int field2; // size=4, offset=4
//  } c;
//  int   i; // size=4, offset=8
//  float f; // size=4, offset=12
//};
