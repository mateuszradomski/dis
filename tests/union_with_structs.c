struct vec3 {
    float x;
    float y;
    float z;
};

union vec3u {
    struct vec3 v3;
    float m[3];
};

int t(union vec3u s) {
    return s.v3.x;
}

//struct vec3 { // size=12
//  float x; // size=4, offset=0
//  float y; // size=4, offset=4
//  float z; // size=4, offset=8
//};
//union vec3u { // size=12
//  vec3  v3;   // size=12, offset=0
//  float m[3]; // size=12, offset=0
//};
