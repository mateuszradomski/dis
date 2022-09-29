struct s {
    int field1;
    int field2;
};

int t(struct s s) {
    return s.field1;
}

//struct s { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
