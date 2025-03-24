
// All includes are ignored
#include <stdint.h>

/// --------------- Functions and macros
int Some_function(uint32_t a, uint32_t b);

int one_more_func(const char** description);

#ifdef TEST_COND
int will_be_declared(uint32_t a, uint32_t b);
#else
int wont_be_declared();
#endif

#define FUNC_MACRO(a, b) a ## b


/// --------------- Types
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

union AStructButUnion
{
  int a;
  float b;
};

/// --------------- Constants
#define HOLLOW___

// TODO: Add filter functions for user to filter out symbols
#define MUST_BE_IGNORED but ... it ... will ... be ... implemented ... later )

#define some_const 69

#define ONE_MORE_CONST (0x23 | 0x24 >> 2)


