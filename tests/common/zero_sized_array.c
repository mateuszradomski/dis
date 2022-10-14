struct zero_sized {
    int count;
    float dynamic_levels[0];
};

int t(struct zero_sized s) {
    return s.count;
}

//struct zero_sized { // size=4
//  int   count;             // size=4, offset=0
//  float dynamic_levels[0]; // size=0, offset=4
//};
