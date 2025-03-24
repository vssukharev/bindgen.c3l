
module bindgen::impl::api @private;

fn String strLowerizeFirst(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_lower();
  return str2;
}

fn String strLowerizeAll(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  foreach (i, &c : str2)
  {
    *c = str[i].to_lower();
  }
  return str2;
}

fn String strCapitalizeFirst(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_upper();
  return str2;
}

fn String strCapitalizeAll(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  for (usz i; i < str.len; ++i) {
    str2[i] = str[i].to_upper();
  }
  return str2;
}

fn String strTranslateType(String str, Allocator alloc) @inline
{
  switch (str)
  {
    case "void": return "void".copy(alloc);
    case "int": return "CInt".copy(alloc);
    case "long long": return "CLongLong".copy(alloc);
    case "short": return "CShort".copy(alloc);
    case "char": return "CChar".copy(alloc);
    case "float": return "float".copy(alloc);
    case "double": return "double".copy(alloc);
    case "unsigned": return "CUInt".copy(alloc);
    case "unsigned int": return "CUInt".copy(alloc);
    case "unsigned short": return "CUShort".copy(alloc);
    case "unsigned char": return "CUChar".copy(alloc);
    case "int8_t": return "ichar".copy(alloc);
    case "int16_t": return "short".copy(alloc);
    case "int32_t": return "int".copy(alloc);
    case "int64_t": return "long".copy(alloc);
    case "uint8_t": return "char".copy(alloc);
    case "uint16_t": return "ushort".copy(alloc);
    case "uint32_t": return "uint".copy(alloc);
    case "uint64_t": return "ulong".copy(alloc);
  }

  return api::strCapitalizeFirst(str, alloc);
}

