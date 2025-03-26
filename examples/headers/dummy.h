
// All includes are ignored
#include <stdint.h>
#include <stddef.h>

/// --------------- Structs

struct incomplete_Distinct_t;

typedef struct WillBeVisible 
{
  int32_t a;
  long long b;
} WillAlsoBeVisible;

struct BitfieldsTranslation
{
  unsigned a;
  int b : 20;
  long c : 12;
  double d;
};

struct NoBitfieldsTranslation
{
  int a : 12;
  int b : 12;
};

struct IgnoreMeToo
{
  double a;
  double b;
};

struct HigherOrder 
{
  int (*f)(int a, double b); 
};

/// --------------- Unions

union AUnion
{
  int a;
  float b;
};

/// --------------- Aliases

typedef int MyInt;
typedef int (*Pfn)(size_t a, ptrdiff_t b);

/// --------------- Functions and macros

int Some_function(uint32_t a, uint32_t b);

int one_more_func(const char** description);

void consequently_ignored(struct IgnoreMeToo a);

#ifdef TEST_COND
int will_be_declared(uint32_t a, uint32_t b);
#else
int wont_be_declared();
#endif

int higher_order(int (*f)(int a, double b), double a);

// #define FUNC_MACRO(a, b) a ## b

/// --------------- Constants

// #define HOLLOW___
//
// #define IGNORE_ME as ... I ... aint ... your ... kind )
//
// #define some_const 69
//
// #define ONE_MORE_CONST (0x23 | 0x24 >> 2)
//
// static const int another_const_1 = 123 + 2 - 2;
//
// const MyInt another_const_2 = 0ULL;

/// --------------- Enums

// enum SomeEnum
// {
//   SOME_MEMBER_1 = 3,
//   SOME_MEMBER_2 = 24,
// };

