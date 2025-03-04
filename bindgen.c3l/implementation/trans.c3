
module bindgen::trans @private;
import bindgen::bg @public;
import clang, std::io;

fn String convStr(CXString s) @inline
{
  return clang::getCString(s).str_view();
}

fn DString* normTypeDStr(DString* ds)
{
  ds.replace("const ", "");
  ds.replace("struct ", "");
  ds.replace("enum ", "");
  return ds;
}

fn String normTypeStr(String s, Allocator allocator = allocator::heap())
{
  DString dstr;
  dstr.tinit();
  defer dstr.free();
  dstr.append(s);
  trans::normTypeDStr(&dstr);
  return dstr.copy_str(allocator);
}

fn String tnormTypeStr(String s) @inline
{
  return normTypeStr(s, allocator::temp());
}


fn String apply(String s, BGTransFn fun, Allocator alloc = allocator::heap()) @inline
{
  return fun != null ? fun(s, alloc) : s.copy(alloc);
}

fn String tapply(String s, BGTransFn fun) @inline
{
  return trans::apply(s, fun);
}

<*
 Applies 'fun' to 's' String, returns the new 
 translated one and caches it into translation 
 table. String itself is always allocated on the
 heap and should NOT be freed as it would cause
 dangerous dead nodes in table.
 @param s "String to translate"
 @param to_save "String to be used as a key in the 'table'. By default, equals to 's'"
*>
fn String capply(String s, BGTransFn fun, TransTable* table, String to_save = "")
{
  if (to_save == "") to_save = s;
  String translated;
  
  if (try cached = (*table)[s])
  {
    translated = cached;
  } 
  else 
  {
    translated = trans::apply(s, fun);
    if (table != null) (*table)[to_save] = translated; // 'translated' is not copied here
  }

  return translated;
}

<*
 TODO: get rid of inner 'const' qualifications, e.g. in 'const char const*'
 Translates 'type' via 'fun' and caches it into 'table'
*>
fn String ctype(
  CXType type,
  BGTransFn fun, 
  TransTable* table)
{
  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = trans::convStr(type_spell);
  
  // Return if cached
  if (try trans_type_str = (*table)[type_str]) return trans_type_str;

  // Here we also need to recursively retrieve inner-most type,
  // like: int[]* -> int. Inner types are those we will be translating
  CXType inner_type = type;
  while LOOP: (true) 
  {
    switch (inner_type.kind)
    {
      case clang::TYPE_POINTER: 
        inner_type = clang::getPointeeType(inner_type);
      case clang::TYPE_CONSTANT_ARRAY:
      case clang::TYPE_INCOMPLETE_ARRAY:
      case clang::TYPE_COMPLEX:
      case clang::TYPE_DEPENDENT_SIZED_ARRAY:
      case clang::TYPE_VECTOR:
        inner_type = clang::getElementType(inner_type);
      default:
        break LOOP;
    }
  }

  CXString inner_type_spell = clang::getTypeSpelling(inner_type);
  defer clang::disposeString(inner_type_spell);
  String inner_type_str = trans::convStr(inner_type_spell);

  @pool()
  {
    // Here, translation is performed under inner type and it's worth to cache also.
    // For example, if we have something like 'CXType*', 'CXType' already must be 
    // defined somewhere and, hence, cached.
    String trans_inner_type_str = trans::capply(inner_type_str, fun, table);

    DString res_dstr;
    res_dstr.tinit();
    res_dstr.append(type_str);
    res_dstr.replace(inner_type_str, trans_inner_type_str);
    trans::normTypeDStr(&res_dstr);

    String res = res_dstr.copy_str(mem);
    (*table)[type_str] = res;

    return res;
  };
}

<*
 The only translation is substituting 'LL' or 'll' to 'L' and 'l' respectively.
 Technically, suffix can be mixed, e.g. 'LLu', 'ull', 'llU' - only 'll'
 and 'LL' must be together and in the same case.
*>
fn String intSuf(String lit, Allocator alloc = allocator::heap())
{
  if (lit.len == 0 || lit[0] == '"') return lit.copy(alloc);

  usz! loc = lit.index_of("LL") ?? lit.index_of("ll");
  if (catch loc) return lit.copy(alloc); // It doesn't contain LL or ll

  String new = (String) allocator::alloc_array(alloc, char, lit.len-1);

  // copy left side
  mem::copy(new.ptr, lit.ptr, loc + 1);

  // copy right side
  if (new.len - loc - 1 > 0) 
  {
    mem::copy(
      new.ptr + (loc + 1), 
      lit.ptr + (loc + 2), 
      new.len - loc - 1
    );
  }

  return new;
}

fn String tintSuf(String lit)
{
  return trans::intSuf(lit, allocator::temp());
}

