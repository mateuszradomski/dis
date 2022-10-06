typedef struct {
    union {
        unsigned int __wch;
        char __wchb[4];
    } __mbstate_t;
    int __count;
    union {
        unsigned int __wch;
        char __wchb[4];
    } __value;
} s;

int t(s s) {
    return s.__count;
}

//struct s { // size=12
//  union { // size=4
//    unsigned int __wch;     // size=4, offset=0
//    char         __wchb[4]; // size=4, offset=0
//  } __mbstate_t;
//  int __count; // size=4, offset=4
//  union { // size=4
//    unsigned int __wch;     // size=4, offset=8
//    char         __wchb[4]; // size=4, offset=8
//  } __value;
//};
