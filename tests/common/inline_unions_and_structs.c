struct first {
    int field1;
    int field2;
    struct {
        double kfield3;
        double kfield4;
    };
    union {
        char kkk;
        void *bbb;
    };
    char arrays[5];
    float vvvs[5];
    struct {
        struct first *next;
        struct first *prev;
    };
};

int t(struct first s) {
    return s.field1;
}

//struct first { // size=80
//  int   field1;    // size=4, offset=0
//  int   field2;    // size=4, offset=4
//  struct { // size=16
//    double kfield3; // size=8, offset=8
//    double kfield4; // size=8, offset=16
//  };
//  union { // size=8
//    char  kkk; // size=1, offset=24
//    void *bbb; // size=8, offset=24
//  };
//  char  arrays[5]; // size=5, offset=32
//  float vvvs[5];   // size=20, offset=40
//  struct { // size=16
//    first *next; // size=8, offset=64
//    first *prev; // size=8, offset=72
//  };
//};
