union u {
    int inting;
    float floating;
};

int t(union u u) {
    return u.inting;
}

//union u { // size=4
//  int   inting;   // size=4, offset=0
//  float floating; // size=4, offset=0
//};
