
import bindgen;
import std::core::ascii, std::io;

String[] defines = {
	"-DVK_ENABLE_BETA_EXTENSIONS",
	"-DVK_USE_PLATFORM_WIN32_KHR",
	"-DVK_USE_PLATFORM_WAYLAND_KHR",
	"-DVK_USE_PLATFORM_XCB_KHR",
	"-DVK_USE_PLATFORM_XLIB_KHR",
	"-DVK_USE_PLATFORM_METAL_EXT",
	"-DVK_USE_PLATFORM_MACOS_MVK", 
};

fn void main(String[] args)
{  
	String out = args.len > 1 ? args[1] : "";

  BGOptions opts_core = {
    .clang_args = defines,
    .module_name = "vulkan::vk",
    .imports = { "std::os::win32" },
    .out_name = out,
    .include_file = &includeFile,
    .skip_errors = true,
    .no_verbose = false,
  }; 

  	BGTransCallbacks trans_cbs = {
		// Strip 'vk' from functions
		.func = fn String(String str, Allocator alloc) =>
			str.strip_prefix("vk").camel_to_snake(alloc),
		.type = &valType,
		// There is a small conflict with variable called 'module'
		.variable = fn String(String str, Allocator alloc) =>
			str == "module" ? "mod" : str.camel_to_snake(alloc),
		// Strip 'VK_' from constans
		.constant = &trans_const,
		.func_macro = &transFuncMacro,
  	};

	BGGenCallbacks gen_cbs = {
		.func_macro = &valFuncMacro,
		.constant = &val_const,
	};

  bg::translate_header("./examples/headers/vulkan/vulkan.h", opts_core, trans_cbs, gen_cbs)!!;
}

fn String trans_const(String name, Allocator alloc) {
	if (name == "VKAPI_CALL") return "";
	if (name == "VKAPI_PTR") return "";
	return name.strip_prefix("VK_").snake_to_screaming(alloc);
}

fn String val_const(String name, Allocator alloc) {
	if (name.contains("NULL_HANDLE"))
	{
		return "null".copy(alloc);
	}
	
	return "";
}

fn String valType(String name, Allocator alloc) {

	if (name.ends_with("_T"))
	{
		return "void".copy(alloc);
	}

	switch (name) {
		case "__IOSurface":
			return "void".copy(alloc);

		case "VkBuffer_T":
		case "VkImage_T":
		case "VkInstance_T":
		case "VkPhysicalDevice_T":
		case "VkDevice_T":
		case "VkQueue_T":
		case "VkSemaphore_T":
		case "VkFence_T":
		case "VkDeviceMemory_T":
		case "VkQueryPool_T":
		case "VkBufferView_T":
		case "VkImageView_T":
		case "VkShaderModule_T":
		case "VkPipelineCache_T":
		case "VkPipelineLayout_T":
		case "VkPipeline_T":
		case "VkRenderPass_T":
		case "VkDescriptorSetLayout_T":
		case "VkSampler_T":
		case "VkDescriptorSet_T":
		case "VkDescriptorPool_T":
		case "VkFramebuffer_T":
		case "VkCommandPool_T":
		case "VkCommandBuffer_T":
		case "VkEvent_T":
			return "void".copy(alloc);

		case "wl_display":
			return "void".copy(alloc);
		case "wl_surface":
			return "void".copy(alloc);

		case "HMONITOR":
			return "Win32_HMONITOR".copy(alloc);
		case "HINSTANCE":
			return "Win32_HINSTANCE".copy(alloc);
		case "HWND":
			return "Win32_HWND".copy(alloc);
		case "HANDLE":
			return "Win32_HANDLE".copy(alloc);
		case "LPCWSTR":
			return "Win32_LPCWSTR".copy(alloc);
		case "LPCWSTR":
			return "Win32_LPCWSTR".copy(alloc);
		case "SECURITY_ATTRIBUTES":
			return "Win32_SECURITY_ATTRIBUTES".copy(alloc);
		case "DWORD":
			return "Win32_DWORD".copy(alloc);
		default: return name.copy(alloc);
	}
}

fn String valFuncMacro(String name, Allocator alloc) {
  switch (name) {
    case "VK_MAKE_API_VERSION":
      return "return (((uint)(#variant)) << 29U) | (((uint)(#major)) << 22U) | (((uint)(#minor)) << 12U) | ((uint)(#patch));".copy(alloc);

    case "VK_API_VERSION_VARIANT":
      return "return (uint)(#version) >> 29U;".copy(alloc);

    case "VK_API_VERSION_MAJOR":
      return "return ((uint)(#version) >> 22U) & 0x7FU;".copy(alloc);

    case "VK_API_VERSION_MINOR":
      return "return ((uint)(#version) >> 12U) & 0x3FFU;".copy(alloc);

    case "VK_API_VERSION_PATCH":
      return "return (uint)(#version) & 0xFFFU;".copy(alloc);

	case "VK_MAKE_VIDEO_STD_VERSION":
		return "return (((uint)(#major)) << 22) | (((uint)(#minor)) << 12) | ((uint)(#patch));";
  }

  return name.copy(alloc);
}

fn String transFuncMacro(String name, Allocator alloc) {
  switch (name) {
    // Ignore these functional macros
    case "VK_DEFINE_HANDLE":
    case "VK_DEFINE_NON_DISPATCHABLE_HANDLE": 
    case "VK_MAKE_VERSION":
    case "VK_VERSION_MAJOR":
    case "VK_VERSION_MINOR":
    case "VK_VERSION_PATCH":
      return "";
  }

  return name.strip_prefix("VK_").screaming_to_snake(alloc);
}

// #include a file only in case it's full path contains 'vulkan/'
fn bool includeFile(String name) {
  return name.contains("vulkan");
}


