struct s {
    int f1;
    int f2;
    union {
        double f3;
        double f4;
        struct {
            char f5;
            char f6;
            union {
                void *f7;
                char *f8;
            };
        };
    };
};

int t(struct s s) {
    return s.f1;
}

//struct s { // size=24
//  int f1; // size=4, offset=0
//  int f2; // size=4, offset=4
//  union { // size=16
//    double f3; // size=8, offset=8
//    double f4; // size=8, offset=8
//    struct { // size=16
//      char f5; // size=1, offset=8
//      char f6; // size=1, offset=9
//      // HOLE => 6 bytes
//      union { // size=8
//        void *f7; // size=8, offset=16
//        char *f8; // size=8, offset=16
//      };
//    };
//  };
//};
