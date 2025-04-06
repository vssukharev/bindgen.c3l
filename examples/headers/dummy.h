
// All includes are ignored
#include <stdint.h>
#include <stddef.h>

/// --------------- Records

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

struct SuspiciousBitfields
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

union AnonUnion
{
  int outer_a;

  struct
  {
    int first_a;
    int first_b;
  } first;
  
  union 
  {
    int second_a;
    int second_b;
  } second;

  struct 
  {
    int inner_a;
    int inner_b;
  };

  char outer_b : 3;
  char outer_c : 5;
};

union AUnion
{
  union unknownT* a;
  float b;
};

struct AlignedBitfields
{
  uint8_t a : 1;
  uint8_t b : 1;
  uint8_t c : 1;
  uint8_t d : 1;
  uint8_t e : 1;
  uint8_t f : 1;
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

#ifdef SOME_PLATFORM
int func_platform1(uint32_t a, uint32_t b);
#else
int func_platform2(uint32_t a, uint32_t b);
#endif

int higher_order(int (*f)(int a, double b), double a);

int (*getFunc(void))(int a, int b);

#define FUNC_MACRO(A, B) A >> B

/// --------------- Constants

#define HOLLOW___

#define IGNORE_ME as ... I ... aint ... your ... kind )

#define some_const 69

#define ONE_MORE_CONST (0x23 | 0x24 >> 2)

static const int another_const_1 = 123 + FUNC_MACRO(8,2);

const MyInt another_const_2 = 0ULL;

const uint32_t hard_const = (uint32_t)(~0U);

/// --------------- Variables

int some_var;
int some_var_with_default = 2;

/// --------------- Enums

enum SomeEnum
{
  SOME_MEMBER_1 = 3,
  SOME_MEMBER_2 = 24,
};

