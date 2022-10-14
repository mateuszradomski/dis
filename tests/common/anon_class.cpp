typedef class {
public:
    int field1;
    int field2;
} anon;

int t(anon a) {
    return a.field1;
}

//class anon { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
