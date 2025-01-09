
module bindgen::bg @private;
import clang, std::io;

<*
 Casts CXString to String without allocations
*>
macro String CXString.toString(self) => 
  clang::getCString(self).str_view();

<*
 Strips redundant prefixes in strings of type 
 spellings without any allocations. 
 E.g. `struct MyStruct` -> `MyStruct`
*>
macro String String.normType(self) => 
  self.strip("struct ").strip("const ").strip("enum ");

<*
 Tranlsates 'self' string and returns the new 
 translated one (or copy of original string).
*>
macro String String.newTrans(self, BGTransFn fun, Allocator alloc = allocator::heap()) =>
  fun != null ? fun(self, alloc) : self.copy(alloc);

macro String String.tempTrans(self, BGTransFn fun) =>
  self.newTrans(fun, allocator::temp()) @inline;

<*
 Translates 'self' string, returns the new 
 translated one and caches it into translation 
 table. String itself is always allocated on the
 heap and should NOT be freed as it would cause
 dangerous dead nodes it table.
*>
fn String String.transCache(self, BGTransFn fun, TransTable* table, Allocator alloc = allocator::heap())
{
  String translated;
  
  if (try cached = (*table)[self])
  {
    translated = cached;
  } 
  else 
  {
    translated = self.newTrans(fun, alloc);
    if (table != null) (*table)[self] = translated; // 'translated' is not copied here
  }

  return translated;
}

<*
 Translates CXType to String
*>
fn String CXType.transCache(
  CXType type,
  BGTransFn fun, 
  TransTable* table)
{
  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = type_spell.toString().normType();
  
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
  String inner_type_str = inner_type_spell.toString().normType();

  // Here, translation is performed under inner type and it's worth to cache also.
  // For example, if we have something like 'CXType*', 'CXType' already must be 
  // defined somewhere and, hence, cached.
  String trans_inner_type_str = inner_type_str.transCache(fun, table);

  @pool()
  {
    DString res_dstr;
    res_dstr.temp_init();
    res_dstr.append(type_str);
    res_dstr.replace(inner_type_str, trans_inner_type_str);

    String res = res_dstr.copy_str();
    (*table)[type_str] = res;

    return res;
  };
}

