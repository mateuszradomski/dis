namespace ns1 {
    class c {
    public:
        int field1;
        int field2;
    };
    namespace ns1_2 {
        class c {
        public:
            char field1;
            char field2;
        };
    }
}

namespace ns2 {
    class c {
    public:
        short field1;
        short field2;
    };
    namespace ns2_2 {
        class c {
        public:
            long long field1;
            long long field2;
        };
    }
}

int t(ns1::c c) {
    return c.field1;
}

int t(ns1::ns1_2::c c) {
    return c.field1;
}

int t(ns2::c c) {
    return c.field1;
}

int t(ns2::ns2_2::c c) {
    return c.field1;
}

//class ns1::c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//class ns1::ns1_2::c { // size=2
//  char field1; // size=1, offset=0
//  char field2; // size=1, offset=1
//};
//class ns2::c { // size=4
//  short field1; // size=2, offset=0
//  short field2; // size=2, offset=2
//};
//class ns2::ns2_2::c { // size=16
//  long long field1; // size=8, offset=0
//  long long field2; // size=8, offset=8
//};
