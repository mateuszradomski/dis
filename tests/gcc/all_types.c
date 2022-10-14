struct all_types_structure {
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
};

int t(struct all_types_structure s) {
    return s.field1;
}

//struct all_types_structure { // size=176
//  char                   field1;  // size=1, offset=0
//  signed char            field2;  // size=1, offset=1
//  unsigned char          field3;  // size=1, offset=2
//  short int              field4;  // size=2, offset=4
//  short int              field5;  // size=2, offset=6
//  short int              field6;  // size=2, offset=8
//  short int              field7;  // size=2, offset=10
//  short unsigned int     field8;  // size=2, offset=12
//  short unsigned int     field9;  // size=2, offset=14
//  int                    field10; // size=4, offset=16
//  int                    field11; // size=4, offset=20
//  int                    field12; // size=4, offset=24
//  unsigned int           field13; // size=4, offset=28
//  unsigned int           field14; // size=4, offset=32
//  long int               field15; // size=8, offset=40
//  long int               field16; // size=8, offset=48
//  long int               field17; // size=8, offset=56
//  long int               field18; // size=8, offset=64
//  long unsigned int      field19; // size=8, offset=72
//  long unsigned int      field20; // size=8, offset=80
//  long long int          field21; // size=8, offset=88
//  long long int          field22; // size=8, offset=96
//  long long int          field23; // size=8, offset=104
//  long long int          field24; // size=8, offset=112
//  long long unsigned int field25; // size=8, offset=120
//  long long unsigned int field26; // size=8, offset=128
//  float                  field27; // size=4, offset=136
//  double                 field28; // size=8, offset=144
//  long double            field29; // size=16, offset=160
//};
