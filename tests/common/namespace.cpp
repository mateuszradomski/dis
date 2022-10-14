namespace testing {
    class c {
        public:
            int field1;
            int field2;
    };

    namespace testing_deeper {
        class c2 {
            public:
                int field1;
                int field2;
        };
    }
}

int t(testing::c c) {
    return c.field1;
}

int t2(testing::testing_deeper::c2 c) {
    return c.field1;
}

//class testing::c { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
//class testing::testing_deeper::c2 { // size=8
//  int field1; // size=4, offset=0
//  int field2; // size=4, offset=4
//};
