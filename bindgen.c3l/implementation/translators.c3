
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
 Translates functions and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_FUNCTION_DECL "Cursor must point to function declaration"
 @returns "Number of bytes written"
*>
fn usz! writeTransFunc(
  GlobalVisitData* vd,
  CXCursor cursor) @maydiscard
{
  usz acc;

  @pool() {
    FuncVisitData vd_func = {
      .g = vd,
    };

    vd_func.params.temp_init(4);
  
    // Translate function parameters and store them into vd_func.params
    clang::visitChildren(cursor, &visitorFunc, (CXClientData) &vd_func);
    
    CXString cursor_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(cursor_spell);
    String original_name = cursor_spell.toString();

    CXString ret_type_spelling = clang::getTypeSpelling(clang::getCursorResultType(cursor));
    defer clang::disposeString(ret_type_spelling);
    String ret_type = ret_type_spelling.toString().normType();

    String translated_name = original_name.trans(vd.trans_fns.func);
  
    // Print everything
    acc += io::fprintf(vd.out, "fn %s %s(", ret_type, translated_name)!;
    foreach (i, p : vd_func.params) 
    {
      acc += io::fprintf(vd.out, "%s %s", p.type, p.name)!;
      if (i < vd_func.params.len()-1) acc += io::fprint(vd.out, ", ")!;
    }
    acc += io::fprintf(vd.out, ") @extern(\"%s\");\n", original_name)!;
  };

  return acc;
}

