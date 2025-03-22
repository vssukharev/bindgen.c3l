
#include <stdint.h>

/*
struct Hello
{
  ulong transform;
  bitstruct : uint
  {
    uint instanceCustomIndex : 0..20;
    ushort mask : 21..23;
  }
  char a;
  bitstruct : ulong
  {
    char instanceShaderBindingTableRecordOffset : 0..6;
    uint flags : 7..33;
  }
  ulong accelerationStructureReference;
}
*/

typedef struct Hello {
    uint64_t transform;
    uint32_t instanceCustomIndex:28;
    uint16_t mask:4;
    uint8_t a;
    uint64_t accelerationStructureReference;
} Hello;

