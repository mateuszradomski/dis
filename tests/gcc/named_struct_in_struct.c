struct simple {
    int field1;
    int field2;
    struct doubles {
        double kfield3;
        double kfield4;
    } ddis;
};

int t(struct simple s) {
    return s.field1;
}

//struct doubles { // size=16
//  double kfield3; // size=8, offset=0
//  double kfield4; // size=8, offset=8
//};
//struct simple { // size=24
//  int     field1; // size=4, offset=0
//  int     field2; // size=4, offset=4
//  doubles ddis;   // size=16, offset=8
//};
