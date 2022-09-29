struct array {
    int field1[4];
    short field2[7];
    char field3[123];
};

int t(struct array s) {
    return s.field1[0];
}

//struct array { // size=156
//  int   field1[4];   // size=16, offset=0
//  short field2[7];   // size=14, offset=16
//  char  field3[123]; // size=123, offset=30
//};
