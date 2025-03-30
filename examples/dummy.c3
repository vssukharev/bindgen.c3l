
import bindgen;
import std::ascii, std::io;

fn String translateType(String str, Allocator alloc)
{
  if (str == "IgnoreMeToo") return "";
  return str.map_basic_type(alloc) ?? bgstr::snake_to_pascal(str, alloc);
}

fn String macroBodies(String name, Allocator alloc)
{
  switch (name)
  {
    case "FUNC_MACRO": return "return #a >> #b;";
    default: return "";
  }
}

fn String varVals(String name, Allocator alloc)
{
  switch (name)
  {
    case "some_var_with_default": return "2";
    default: return "";
  }
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";

  BGTransCallbacks tcb = {
    .func = &bgstr::snake_to_camel,
    .type = &translateType,
    .func_macro = &bgstr::screaming_to_snake,
    .variable = &bgstr::pascal_to_snake,
    .constant = fn String(String str, Allocator alloc) => 
      str != "IGNORE_ME" ? str.snake_to_screaming(alloc) : "",
  };

  BGGenCallbacks gcb = {
    .func_macro = &macroBodies,
    .global_var = &varVals,
  };

  bg::translate_headers({ "./examples/headers/dummy.h" }, out, "dummy", tcb, gcb, { "-DTEST_COND" })!!;
}

