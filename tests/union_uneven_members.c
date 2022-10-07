struct vec3 {
    float x;
    float y;
    float z;
};

union vec3u {
    struct vec3 v3;
    int inting;
    char charing;
    char whoosh[15];
};

int t(union vec3u s) {
    return s.v3.x;
}

//union vec3u { // size=16
//  vec3 v3;         // size=12, offset=0
//  int  inting;     // size=4, offset=0
//  char charing;    // size=1, offset=0
//  char whoosh[15]; // size=15, offset=0
//};
//struct vec3 { // size=12
//  float x; // size=4, offset=0
//  float y; // size=4, offset=4
//  float z; // size=4, offset=8
//};
