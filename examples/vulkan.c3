
import bindgen;
import std::ascii, std::io;

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGOptions opts = {
    .clang_args = { "-DVK_ENABLE_BETA_EXTENSIONS" },
    .module_name = "vulkan::vk",
    .out_name = out,
    .include_file = &includeFile,
    .skip_errors = true,
    .no_verbose = true,
  }; 

  BGTransCallbacks trans_cbs = {
    // Strip 'vk' from functions
    .func = fn String(String str, Allocator alloc) =>
      str.strip("vk").camel_to_snake(alloc),
    // There is a small conflict with variable called 'module'
    .variable = fn String(String str, Allocator alloc) =>
      str == "module" ? "mod" : str.camel_to_snake(alloc),
    // Strip 'VK_' from constans
    .constant = fn String(String str, Allocator alloc) =>
      str.strip("VK_").snake_to_screaming(alloc),

    .func_macro = &transFuncMacro,
  };

  BGGenCallbacks gen_cbs = {
    .func_macro = &valFuncMacro,
  };

  bg::translate_header("./examples/headers/vulkan-part.h", opts, trans_cbs, gen_cbs)!!;
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

  return name.strip("VK_").screaming_to_snake(alloc);
}

// #include a file only in case it's full path contains 'vulkan/'
fn bool includeFile(String name) {
  return name.contains("vulkan/");
}


