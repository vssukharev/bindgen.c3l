
module bindgen::bg @private;
import std::io, clang;

<*
 Translates functions and writes it to 'vd.out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_FUNCTION_DECL "Cursor must point to function declaration"
 @returns "Number of bytes written"
*>
fn usz! transFunc(
  GlobalVisitData* vd,
  CXCursor cursor)
@maydiscard
{
  @pool() {
    FuncVisitData vd_func = {
      .g = vd,
    };

    vd_func.params.temp_init(4);
  
    // Translate function parameters and store them into vd_func.params
    clang::visitChildren(cursor, &visitorFunc, (CXClientData) &vd_func);
    
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


