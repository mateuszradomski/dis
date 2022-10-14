struct s {
    int f1;
    void *ptr1;
    void **ptr2;
    void ***ptr3;
    void ****ptr4;
    void *****ptr5;
    void ******ptr6;
    void *******ptr7;
};

int t(struct s s) {
    return s.f1;
}

//struct s { // size=64
//  int         f1;   // size=4, offset=0
//  void *      ptr1; // size=8, offset=8
//  void **     ptr2; // size=8, offset=16
//  void ***    ptr3; // size=8, offset=24
//  void ****   ptr4; // size=8, offset=32
//  void *****  ptr5; // size=8, offset=40
//  void ****** ptr6; // size=8, offset=48
//  void *******ptr7; // size=8, offset=56
//};
