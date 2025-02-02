
import bindgen;
import std::ascii, std::io;

fn String lowerizeFirst(String str, Allocator alloc)
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_lower();
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

fn String translateConstant(String str, Allocator alloc)
{
  return str.copy(alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &lowerizeFirst,
    .type = &translateType,
    .variable = &lowerizeFirst,
    .constant = &capitalize,
  };

  bg::translateHeaders({"./examples/headers/glfw3.h"}, out, cb, "glfw")!!;
}

