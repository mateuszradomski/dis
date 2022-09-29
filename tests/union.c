union u {
    int inting;
    float floating;
};

int t(union u s) {
    return s.inting;
}

//union u { // size=4
//  int   inting;   // size=4, offset=0
//  float floating; // size=4, offset=0
//};
