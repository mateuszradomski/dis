struct all_types_and_ptrs_structure {
  char field1;
  signed char field2;
  unsigned char field3;
  short field4;
  short int field5;
  signed short field6;
  signed short int field7;
  unsigned short field8;
  unsigned short int field9;
  int field10;
  signed field11;
  signed int field12;
  unsigned field13;
  unsigned int field14;
  long field15;
  long int field16;
  signed long field17;
  signed long int field18;
  unsigned long field19;
  unsigned long int field20;
  long long field21;
  long long int field22;
  signed long long field23;
  signed long long int field24;
  unsigned long long field25;
  unsigned long long int field26;
  float field27;
  double field28;
  long double field29;
  char *field1_ptr;
  signed char *field2_ptr;
  unsigned char *field3_ptr;
  short *field4_ptr;
  short int *field5_ptr;
  signed short *field6_ptr;
  signed short int *field7_ptr;
  unsigned short *field8_ptr;
  unsigned short int *field9_ptr;
  int *field10_ptr;
  signed *field11_ptr;
  signed int *field12_ptr;
  unsigned *field13_ptr;
  unsigned int *field14_ptr;
  long *field15_ptr;
  long int *field16_ptr;
  signed long *field17_ptr;
  signed long int *field18_ptr;
  unsigned long *field19_ptr;
  unsigned long int *field20_ptr;
  long long *field21_ptr;
  long long int *field22_ptr;
  signed long long *field23_ptr;
  signed long long int *field24_ptr;
  unsigned long long *field25_ptr;
  unsigned long long int *field26_ptr;
  float *field27_ptr;
  double *field28_ptr;
  long double *field29_ptr;
};

int t(struct all_types_and_ptrs_structure s) {
    return s.field1;
}

//struct all_types_and_ptrs_structure { // size=416
//  char                field1;      // size=1, offset=0
//  signed char         field2;      // size=1, offset=1
//  unsigned char       field3;      // size=1, offset=2
//  short               field4;      // size=2, offset=4
//  short               field5;      // size=2, offset=6
//  short               field6;      // size=2, offset=8
//  short               field7;      // size=2, offset=10
//  unsigned short      field8;      // size=2, offset=12
//  unsigned short      field9;      // size=2, offset=14
//  int                 field10;     // size=4, offset=16
//  int                 field11;     // size=4, offset=20
//  int                 field12;     // size=4, offset=24
//  unsigned int        field13;     // size=4, offset=28
//  unsigned int        field14;     // size=4, offset=32
//  long                field15;     // size=8, offset=40
//  long                field16;     // size=8, offset=48
//  long                field17;     // size=8, offset=56
//  long                field18;     // size=8, offset=64
//  unsigned long       field19;     // size=8, offset=72
//  unsigned long       field20;     // size=8, offset=80
//  long long           field21;     // size=8, offset=88
//  long long           field22;     // size=8, offset=96
//  long long           field23;     // size=8, offset=104
//  long long           field24;     // size=8, offset=112
//  unsigned long long  field25;     // size=8, offset=120
//  unsigned long long  field26;     // size=8, offset=128
//  float               field27;     // size=4, offset=136
//  double              field28;     // size=8, offset=144
//  long double         field29;     // size=16, offset=160
//  char *              field1_ptr;  // size=8, offset=176
//  signed char *       field2_ptr;  // size=8, offset=184
//  unsigned char *     field3_ptr;  // size=8, offset=192
//  short *             field4_ptr;  // size=8, offset=200
//  short *             field5_ptr;  // size=8, offset=208
//  short *             field6_ptr;  // size=8, offset=216
//  short *             field7_ptr;  // size=8, offset=224
//  unsigned short *    field8_ptr;  // size=8, offset=232
//  unsigned short *    field9_ptr;  // size=8, offset=240
//  int *               field10_ptr; // size=8, offset=248
//  int *               field11_ptr; // size=8, offset=256
//  int *               field12_ptr; // size=8, offset=264
//  unsigned int *      field13_ptr; // size=8, offset=272
//  unsigned int *      field14_ptr; // size=8, offset=280
//  long *              field15_ptr; // size=8, offset=288
//  long *              field16_ptr; // size=8, offset=296
//  long *              field17_ptr; // size=8, offset=304
//  long *              field18_ptr; // size=8, offset=312
//  unsigned long *     field19_ptr; // size=8, offset=320
//  unsigned long *     field20_ptr; // size=8, offset=328
//  long long *         field21_ptr; // size=8, offset=336
//  long long *         field22_ptr; // size=8, offset=344
//  long long *         field23_ptr; // size=8, offset=352
//  long long *         field24_ptr; // size=8, offset=360
//  unsigned long long *field25_ptr; // size=8, offset=368
//  unsigned long long *field26_ptr; // size=8, offset=376
//  float *             field27_ptr; // size=8, offset=384
//  double *            field28_ptr; // size=8, offset=392
//  long double *       field29_ptr; // size=8, offset=400
//};
