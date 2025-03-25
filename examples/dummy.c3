
import bindgen;
import std::ascii, std::io;

fn String translateFuncMacro(String str, Allocator alloc)
{
  String a = str.strip("VK_");
  return bgstr::lowerize_all(a, alloc);
}

fn String translateType(String str, Allocator alloc)
{
  if (str == "IgnoreMeToo")
  {
    return "";
  }

  return bgstr::translate_type(str, alloc);
}

fn String translateConstant(String str, Allocator alloc)
{
  if (str == "IGNORE_ME")
  {
    return "";
  }

  return bgstr::capitalize_all(str, alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
 
  // String name = "__OneTwoThree__";
  // io::printfn("%s -> %s", name, bgstr::camel_to_snake(name, mem));
  
  BGTransCallbacks cb = {
    .func = &bgstr::lowerize_first,
    .type = &translateType,
    .variable = &bgstr::lowerize_first,
    .constant = &translateConstant,
    .func_macro = &translateFuncMacro,
  };

  bg::translate_headers({"./examples/headers/dummy.h"}, out, cb, "dummy", { "-DTEST_COND" })!!;
}

