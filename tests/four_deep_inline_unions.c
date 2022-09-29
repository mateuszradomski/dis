union u {
    int f1;
    int f2;
    union {
        double f3;
        double f4;
        union {
            char f5;
            char f6;
            union {
                void *f7;
                char *f8;
            };
        };
    };
};

int t(union u s) {
    return s.f1;
}

//union u { // size=8
//  int f1; // size=4, offset=0
//  int f2; // size=4, offset=0
//  union { // size=8
//    double f3; // size=8, offset=0
//    double f4; // size=8, offset=0
//    union { // size=8
//      char f5; // size=1, offset=0
//      char f6; // size=1, offset=0
//      union { // size=8
//        void *f7; // size=8, offset=0
//        char *f8; // size=8, offset=0
//      };
//    };
//  };
//};
