
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

    @pool()
    {
      String orig_name = cursor_spell.toString();
      String name = orig_name.trans(vd.trans_fns.func);
      String ret_type_name = clang::getCursorResultType(cursor).ttrans(vd.trans_fns.type, &vd.types_table);

      return writeFunc(vd.out, vd_func.params.array_view(), ret_type_name, orig_name, name);
    };
  };
}


