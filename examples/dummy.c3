
import bindgen;
import std::ascii, std::io;

fn String translateType(String str, Allocator alloc)
{
  // Ignore IgnoreMeToo type
  if (str == "IgnoreMeToo") return "";
  // If the type is not basic, just return a copy
  return str.map_basic_type(alloc) ?? bgstr::snake_to_pascal(str, alloc);
}

fn String macroBodies(String name, Allocator alloc)
{
  switch (name)
  {
    case "FUNC_MACRO":  return "return #a >> #b;";
    default:            return "";
  }
}

fn String genVarVal(String name, Allocator alloc)
{
  switch (name)
  {
    case "some_var_with_default": return "2";
    default:                      return "";
  }
}

fn String genConstVal(String name, Allocator alloc)
{
  switch (name)
  {
    case "hard_const": return "(uint)(~0U)";
    default:           return "";
  }
}

fn String genIfArg(String name, Allocator alloc)
{
  switch (name) 
  {
    case "func_platform1":  return "$defined(env::SOME_PLATFORM)";
    case "func_platform2":  return "!$defined(env::SOME_PLATFORM)";
    default:                return "";
  }
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";

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
    .variable = &genVarVal,
    .constant = &genConstVal,
    .if_condition = &genIfArg,
  };

  BGOptions opts = {
    .clang_args = { "-DTEST_COND" },
    .out_name = out,
    .module_name = "dummy",
  };

  bg::translate_header("./examples/headers/dummy.h", tcb, opts, gcb)!!;
}

