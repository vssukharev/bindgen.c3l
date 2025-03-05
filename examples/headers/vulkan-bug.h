
#include <stdint.h>

typedef uint32_t VkDevice;
typedef void VkBufferDeviceAddressInfo;
typedef void VkDeviceMemoryOpaqueCaptureAddressInfo;

typedef uint64_t (*PFN_vkGetBufferOpaqueCaptureAddress)(VkDevice device, VkBufferDeviceAddressInfo* pInfo);
typedef uint64_t (*PFN_vkGetDeviceMemoryOpaqueCaptureAddress)(VkDevice device, VkDeviceMemoryOpaqueCaptureAddressInfo* pInfo);





