
import bindgen;
import std::ascii, std::io;

fn String translateType(String str, Allocator alloc)
{
  if (str == "IgnoreMeToo") return "";
  return str.map_basic_type(alloc) ?? bgstr::snake_to_pascal(str, alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";

  BGTransCallbacks cb = {
    .func = &bgstr::snake_to_camel,
    .type = &translateType,
    .func_macro = &bgstr::screaming_to_snake,
    .variable = null,
    .constant = fn String(String str, Allocator alloc) => 
      str != "IGNORE_ME" ? str.snake_to_screaming(alloc) : "",
  };

  bg::translate_headers({ "./examples/headers/dummy.h" }, out, cb, "dummy", { "-DTEST_COND" })!!;
}

