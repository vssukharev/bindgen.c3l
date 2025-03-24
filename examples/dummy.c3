
import bindgen;
import std::ascii, std::io;

fn String translateFuncMacro(String str, Allocator alloc)
{
  String a = str.strip("VK_");
  return bgstr::lowerize_all(a, alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &bgstr::lowerize_first,
    .type = &bgstr::translate_type,
    .variable = &bgstr::lowerize_first,
    .constant = &bgstr::capitalize_all,
    .func_macro = &translateFuncMacro,
  };

  bg::translate_headers({"./examples/headers/dummy.h"}, out, cb, "dummy", { "-DTEST_COND" })!!;
}

