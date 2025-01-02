
module bindgen::bg @private;
import std::io, clang;

<*
 Tranlsates 'self' string and returns the new 
 translated one (or copy of original string).
*>
macro String String.trans(self, BGTransFn fun)
{
  return fun != null ? fun(self) : self.copy();
}


<*
 Tranlsates 'self' string, returns the new 
 translated one (or copy of original string)
 and caches it into translation table.
*>
macro String String.transCached(val, BGTransFn fun, TransTable* table)
{
  String translated;
  
  if (try cached = (*table)[val]) 
  {
    translated = cached;
  } 
  else 
  {
    translated = val.trans(fun);
    table.set(val, translated);
  }

  return translated;
}


<*
 Translates functions and writes it to 'vd.out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_FUNCTION_DECL "Cursor must point to function declaration"
 @returns "Number of bytes written"
*>
fn usz! transFunc(
  GlobalVisitData* vd,
  CXCursor cursor,
  CXCursorVisitor visitor) 
@maydiscard
{
  @pool() {
    FuncVisitData vd_func = {
      .g = vd,
    };

    vd_func.params.temp_init(4);
  
    // Translate function parameters and store them into vd_func.params
    clang::visitChildren(cursor, visitor, (CXClientData) &vd_func);
    
    CXString cursor_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(cursor_spell);
    String orig_name = cursor_spell.toString();

    CXString ret_type_spelling = clang::getTypeSpelling(clang::getCursorResultType(cursor));
    defer clang::disposeString(ret_type_spelling);
    String ret_type = ret_type_spelling.toString().normType();
 
    return writeFunc(
      vd.out, 
      vd_func.params.array_view(), 
      ret_type, 
      orig_name, 
      orig_name.trans(vd.trans_fns.func)
    );
  };
}


<*
 Translates structure declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_STRUCT_DECL "Cursor must point to structure declaration"
 @returns "Number of bytes written"
*>
fn usz! transStruct(
  GlobalVisitData* vd,
  CXCursor cursor,
  CXCursorVisitor visitor) 
@maydiscard
{
  @pool() {
    StructVisitData vd_struct = {
      .g = vd,
    };

    vd_struct.fields.temp_init(4);
  
    // Translate function parameters and store them into vd_struct.fields
    clang::visitChildren(cursor, visitor, (CXClientData) &vd_struct);
    
    CXString cursor_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(cursor_spell);

    return writeStruct(
      vd.out,
      vd_struct.fields.array_view(),
      cursor_spell.toString().trans(vd.trans_fns.type) 
    );
  };
}


<*
 Translates alias declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_TYPEDEF_DECL "Cursor must point to typedef declaration"
 @returns "Number of bytes written"
*>
fn usz! transTypedef(
  GlobalVisitData* vd,
  CXCursor cursor,
  CXCursorVisitor visitor) @maydiscard
{
  @pool() {
    TypedefVisitData vd_typedef = {
      .g = vd,
    };
  
    // Translate function parameters and store them into vd_struct.fields
    clang::visitChildren(cursor, visitor, (CXClientData) &vd_typedef);
    
    CXString cursor_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(cursor_spell);

    String trans_name = cursor_spell.toString().trans(vd.trans_fns.type);
  
    return writeFuncTypedef(vd.out);
  };
}

