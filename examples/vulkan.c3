
import bindgen;
import std::ascii, std::io;

fn String translateFunc(String str, Allocator alloc)
{
  return bgstr::lowerize_first(str.strip("vk"), alloc);
}

fn String translateConstant(String str, Allocator alloc)
{
  return bgstr::capitalize_all(str.strip("VK_"), alloc);
}

fn String translateFuncMacro(String str, Allocator alloc)
{
  return bgstr::lowerize_all(str.strip("VK_"), alloc);
}

fn String translateVar(String str, Allocator alloc)
{
  if (str == "module")
  {
    return "cmodule".copy(alloc);
  }
  return bgstr::lowerize_first(str, alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &translateFunc,
    .type = &bgstr::translate_type,
    .variable = &translateVar,
    .constant = &translateConstant,
    .func_macro = &translateFuncMacro,
  };

  bg::translate_headers({"./examples/headers/vulkan-part.h"}, out, cb, "vulkan::vk", { "-DVK_ENABLE_BETA_EXTENSIONS" })!!;
}


