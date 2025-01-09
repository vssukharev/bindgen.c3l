
module bindgen::bg @private;
import std::io, clang;

<*
 Translates functions and writes it to 'vd.out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_FUNCTION_DECL "Cursor must point to function declaration"
 @returns "Number of bytes written"
*>
fn usz! transWriteFunc(GlobalVisitData* vd, CXCursor cursor) @maydiscard
{
  @pool() 
  {
    FuncVisitData vd_func = {
      .g = vd,
      .allocator = allocator::temp(),
    };

    vd_func.params.temp_init(4);
  
    // Translate function parameters and store them into vd_func.params
    clang::visitChildren(cursor, &visitorFunc, (CXClientData) &vd_func);
    
    CXString func_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(func_spell);
    String func_str = func_spell.toString();

    String trans_func_str = func_str.tempTrans(vd.trans_fns.func);
    String trans_ret_type_str = clang::getCursorResultType(cursor).transCache(vd.trans_fns.type, &vd.types_table);

    return writeFunc(vd.out, vd_func.params.array_view(), trans_ret_type_str, func_str, trans_func_str);
  };
}


