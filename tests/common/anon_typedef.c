typedef struct {
    int field1;
    char* field2;
} typedefed;

int t(typedefed s) {
    return s.field1;
}

//struct typedefed { // size=16
//  int   field1; // size=4, offset=0
//  // HOLE => 4 bytes
//  char *field2; // size=8, offset=8
//};
