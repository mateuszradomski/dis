struct s {
    int field1 : 1;
    int field2 : 2;
    int field3 : 3;
    int field4 : 4;
    int field5 : 5;
    int field6 : 6;
    int field7 : 7;
};

struct s2 {
    int field1 : 5;
    int field2 : 9;
    int field3 : 1;
    int field4 : 7;
    int field5 : 10;
};

struct s3 {
    int field1 : 10;
    int field2 : 10;
};

int t(struct s s, struct s2 s2, struct s3 s3) {
    return s.field1 + s2.field1 + s3.field1;
}

//struct s { // size=4
//  int field1:1; // size=4, offset=0:0
//  int field2:2; // size=4, offset=0:1
//  int field3:3; // size=4, offset=0:3
//  int field4:4; // size=4, offset=0:6
//  int field5:5; // size=4, offset=0:10
//  int field6:6; // size=4, offset=0:15
//  int field7:7; // size=4, offset=0:21
//  // HOLE => 4 bits
//};
//struct s2 { // size=4
//  int field1:5;  // size=4, offset=0:0
//  int field2:9;  // size=4, offset=0:5
//  int field3:1;  // size=4, offset=0:14
//  int field4:7;  // size=4, offset=0:15
//  int field5:10; // size=4, offset=0:22
//};
//struct s3 { // size=4
//  int field1:10; // size=4, offset=0:0
//  int field2:10; // size=4, offset=0:10
//  // HOLE => 1 bytes and 4 bits
//};
