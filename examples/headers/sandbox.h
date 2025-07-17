

struct Hello {
  struct Dsa { int a; } dsa;
  union { double b; } sda;
  enum Asd {
    FOUR,
    FIVE,
    SIX
  } _kind2;
  enum {
    ONE, 
    TWO, 
    THREE
  } _kind1;
  struct UnknownT* ut;
};


