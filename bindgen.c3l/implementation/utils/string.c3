
module bindgen::bg @private;
import clang, std::io;

<*
 Casts CXString to String without allocations
*>
fn String CXString.toString(self) @inline => 
  clang::getCString(self).str_view();

<*
 Same as DString.normType but creates a new string
*>
fn String String.normType(self, Allocator allocator) @inline
{
  DString dstr;
  dstr.temp_init();
  defer dstr.free();
  dstr.append(self);
  dstr.normType();
  return dstr.copy_str(allocator);
}

<*
 Normalizes types by deleting redundant infixes
*>
fn DString DString.normType(self)
{
  self.replace("const ", "");
  self.replace("struct ", "");
  self.replace("enum ", "");
  return self;
}

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
 TODO: get rid of inner 'const' qualifications, e.g. in 'const char const*'
 Translates CXType to String
*>
fn String CXType.transCache(
  CXType type,
  BGTransFn fun, 
  TransTable* table)
{
  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = type_spell.toString();
  
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
  String inner_type_str = inner_type_spell.toString();

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
    res_dstr.normType();

    String res = res_dstr.copy_str();
    (*table)[type_str] = res;

    return res;
  };
}

