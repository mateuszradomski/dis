union simple {
    int field1;
    int field2;
    struct {
        double kfield3;
        double kfield4;
    };
};

int t(union simple s) {
    return s.field1;
}

//union simple { // size=16
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=0
//  struct { // size=16
//    double kfield3; // size=8, offset=0
//    double kfield4; // size=8, offset=8
//  };
//};
