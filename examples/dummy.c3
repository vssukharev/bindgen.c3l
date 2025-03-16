
import bindgen;
import std::ascii, std::io;

fn String lowerizeFirst(String str, Allocator alloc)
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_lower();
  return str2;
}

fn String lowerizeAll(String str, Allocator alloc)
{
  String str2 = str.copy(alloc);
  foreach (i, &c : str2)
  {
    *c = str[i].to_lower();
  }
  return str2;
}


fn String capitalizeFirst(String str, Allocator alloc)
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_upper();
  return str2;
}

fn String capitalize(String str, Allocator alloc)
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  for (usz i; i < str.len; ++i) {
    str2[i] = str[i].to_upper();
  }
  return str2;
}

fn String translateType(String str, Allocator alloc)
{
  switch (str)
  {
    case "void": return "void".copy(alloc);
    case "uint32_t": return "uint".copy(alloc);
    case "uint64_t": return "ulong".copy(alloc);
    case "int": return "CInt".copy(alloc);
    case "unsigned": return "CUInt".copy(alloc);
    case "unsigned int": return "CUInt".copy(alloc);
    case "unsigned short": return "CUShort".copy(alloc);
    case "unsigned char": return "CUChar".copy(alloc);
    case "long long": return "CLongLong".copy(alloc);
    case "short": return "CShort".copy(alloc);
    case "char": return "CChar".copy(alloc);
    case "double": return "double".copy(alloc);
    case "float": return "float".copy(alloc);
  }

  return capitalizeFirst(str, alloc);
}

fn String translateFuncMacro(String str, Allocator alloc)
{
  return lowerizeAll(str.strip("VK_"), alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &lowerizeFirst,
    .type = &translateType,
    .variable = &lowerizeFirst,
    .constant = &capitalize,
    .func_macro = &translateFuncMacro,
  };

  bg::translateHeaders({"./examples/headers/dummy.h"}, out, cb, "dummy")!!;
}

