
module bindgen::bg @private;
import clang, std::io;

<*
 Casts CXString to String without allocations
*>
macro String CXString.toString(self) => 
  clang::getCString(self).str_view();

<*
 Delete redundant prefixes in strings of type 
 spellings, e.g. `struct MyStruct` -> `MyStruct`
*>
macro String String.normType(self) => 
  self.strip("struct ").strip("const ");

<*
 Tranlsates 'self' string and returns the new 
 translated one (or copy of original string).
*>
macro String String.trans(self, BGTransFn fun) =>
  fun != null ? fun(self) : self.copy();

<*
 Translates 'self' string, returns the new 
 translated one (or copy of original string)
 and caches it into translation table.
*>
fn String String.transCached(self, BGTransFn fun, TransTable* table)
{
  String translated;
  
  if (try cached = (*table)[self]) 
  {
    translated = cached;
  } 
  else 
  {
    translated = self.trans(fun);
    if (table != null) table.set(self, translated);
  }

  return translated;
}

<*
 TODO: make it more efficient
 Translated CXType to String
 @returns "String, allocated via 'allocator'"
*>
fn String CXType.trans(
  type,
  BGTransFn fun, 
  TransTable* table, 
  Allocator allocator = allocator::heap())
{
  CXType base_type = type;
  
  while LOOP: (true) 
  {
    switch (base_type.kind)
    {
      case clang::TYPE_POINTER: 
        base_type = clang::getPointeeType(base_type);
      case clang::TYPE_CONSTANT_ARRAY:
      case clang::TYPE_INCOMPLETE_ARRAY:
      case clang::TYPE_COMPLEX:
      case clang::TYPE_DEPENDENT_SIZED_ARRAY:
      case clang::TYPE_VECTOR:
        base_type = clang::getElementType(base_type);
      default:
        break LOOP;
    }
  }

  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  CXString base_type_spell = clang::getTypeSpelling(base_type);
  defer clang::disposeString(base_type_spell);

  String base_type_str = base_type_spell.toString().normType();
  String trans_base_type_str = base_type_str.transCached(fun, table);
  String type_str = type_spell.toString().normType();

  DString type_name;
  type_name.temp_init();
  defer type_name.free();
  type_name.append(type_str);
  type_name.replace(base_type_str, trans_base_type_str);

  return type_name.copy_str(allocator);
}

<*
 Same as transType but allocates the String via temp allocator
*>
macro String CXType.ttrans(type, BGTransFn fun, TransTable* table) => type.trans(fun, table, allocator::temp());

