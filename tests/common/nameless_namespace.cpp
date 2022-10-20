namespace {
    class c {
        public:
            int field1;
            int field2;
    };

    namespace {
        class c2 {
            public:
                int field1;
                int field2;
        };
    }
}

int t() {
    c c;
    return c.field1;
}

int t2() {
    c2 c;
    return c.field1;
}

//class c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//class c2 { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
