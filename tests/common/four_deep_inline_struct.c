struct s {
    int f1;
    int f2;
    struct {
        double f3;
        double f4;
        struct {
            char f5;
            char f6;
            struct {
                void *f7;
                char *f8;
            };
        };
    };
};

int t(struct s s) {
    return s.f1;
}

//struct s { // size=48
//  int f1; // size=4, offset=0
//  int f2; // size=4, offset=4
//  struct { // size=40
//    double f3; // size=8, offset=8
//    double f4; // size=8, offset=16
//    struct { // size=24
//      char f5; // size=1, offset=24
//      char f6; // size=1, offset=25
//      struct { // size=16
//        void *f7; // size=8, offset=32
//        char *f8; // size=8, offset=40
//      };
//    };
//  };
//};
