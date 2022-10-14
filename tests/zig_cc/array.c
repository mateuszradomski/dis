struct array {
    int field1[4];
    short field2[7];
    char field3[123];
    char field4[2][4];
    float field5[2][4][45];
};

int t(struct array s) {
    return s.field1[0];
}

//struct array { // size=1604
//  int   field1[4];   // size=16, offset=0
//  short field2[7];   // size=14, offset=16
//  char  field3[123]; // size=123, offset=30
//  char  field4[8];   // size=8, offset=153
//  float field5[360]; // size=1440, offset=164
//};
