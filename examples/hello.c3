
import bindgen;
import std::ascii, std::io;

fn String lowerizeFirst(String str)
{
  String str2 = str.copy();
  if (str.len == 0) return str2;
  str2[0] = str[0].to_lower();
  return str2;
}

fn String capitalizeFirst(String str)
{
  String str2 = str.copy();
  if (str.len == 0) return str2;
  str2[0] = str[0].to_upper();
  return str2;
}

fn String capitalize(String str)
{
  String str2 = str.copy();
  if (str.len == 0) return str2;
  for (usz i; i < str.len; ++i) {
    str2[i] = str[i].to_upper();
  }
  return str2;
}

fn String translateType(String str)
{
  switch (str)
  {
    case "int": return "CInt";
    case "unsigned": return "CUInt";
    case "unsigned int": return "CUInt";
    case "short": return "CShort";
  }

  return capitalizeFirst(str);
}

fn String translateConstant(String str, Allocator alloc = allocator::heap())
{
  return str.copy();
}


fn void! main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &lowerizeFirst,
    .type = &translateType,
    .variable = &lowerizeFirst,
    .constant = &capitalize,
  };

  bg::translateHeader("./examples/headers/dummy.h", out, cb)!;
}

