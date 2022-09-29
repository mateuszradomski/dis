union first {
    int inting;
    char charing;
};

union second {
    char whoosh[15];
    float boosh[4];
};

union third {
    union first f;
    union second s;
};

int t(union third s) {
    return s.f.inting;
}

//union third { // size=16
//  first  f; // size=4, offset=0
//  second s; // size=16, offset=0
//};
//union first { // size=4
//  int  inting;  // size=4, offset=0
//  char charing; // size=1, offset=0
//};
//union second { // size=16
//  char  whoosh[15]; // size=15, offset=0
//  float boosh[4];   // size=16, offset=0
//};
