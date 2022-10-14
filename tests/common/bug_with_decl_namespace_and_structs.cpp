class decl;

namespace ns {
    class c {
        public:
            decl *d;
            int field1;
            int field2;
    };
}

class c2 {
public:
    char f1;
    char f2;
};

int t(ns::c c, c2 c2) {
    return c.field1 + c2.f1;
}

//class ns::c { // size=16
//  decl *d;      // size=8, offset=0
//  int   field1; // size=4, offset=8
//  int   field2; // size=4, offset=12
//};
//class c2 { // size=2
//  char f1; // size=1, offset=0
//  char f2; // size=1, offset=1
//};
