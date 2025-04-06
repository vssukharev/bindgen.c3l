
import bindgen;
import std::ascii, std::io;

fn String valFuncMacro(String name, Allocator alloc)
{
  switch (name)
  {
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

fn String transFuncMacro(String name, Allocator alloc)
{
  switch (name)
  {
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

fn bool includeFile(String name)
{
  return name.contains("vulkan/");
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGTransCallbacks trans_cbs = {
    .func = fn String(String str, Allocator alloc) =>
      str.strip("vk").camel_to_snake(alloc),

    .type = fn String(String str, Allocator alloc) =>
      str.map_basic_type(alloc) ?? str.copy(alloc),

    .variable = fn String(String str, Allocator alloc) =>
      str == "module" ? "mod" : str.camel_to_snake(alloc),
      
    .constant = fn String(String str, Allocator alloc) =>
      str.strip("VK_").snake_to_screaming(alloc),

    .func_macro = &transFuncMacro,
  };

  BGGenCallbacks gen_cbs = {
    .func_macro = &valFuncMacro,
  };

  BGOptions opts = {
    .clang_args = { "-DVK_ENABLE_BETA_EXTENSIONS" },
    .module_name = "vulkan::vk",
    .out_name = out,
    .include_file = &includeFile,
    .skip_errors = true,
    .no_verbose = true,
  }; 

  bg::translate_header("./examples/headers/vulkan-part.h", trans_cbs, opts, gen_cbs)!!;
}


