
/*
macro @vkApiVersionVariant(#version)
{
  return (uint)(#version) >> 29U
}
*/

#define VK_API_VERSION_MAJOR(version) (((uint32_t)(version) >> 22U) & 0x7FU)
#define MACRO_FUN(arg1, arg2, base) base##t // unchanged

