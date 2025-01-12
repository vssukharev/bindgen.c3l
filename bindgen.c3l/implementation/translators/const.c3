
module bindgen::bg @private;
import std::io, clang;

<*
 Translates global constant declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_VAR_DECL "Cursor must point to variable declaration"
 @returns "Number of bytes written"
*>
fn usz! transWriteConst(GlobalVisitData* vd, CXCursor cursor) @maydiscard
{
  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = cursor_spell.toString();

  CXType cursor_type = clang::getCursorType(cursor);

  @pool()
  {
    ConstVisitData vd_const = { .g = vd };
    vd_const.val.temp_init();

    // Visit rhs of var declaration and translate 
    // there everything, that is identifier
    clang::visitChildren(cursor, &visitorConst, (CXClientData) &vd_const);
    
    String name = cursor_str.tempTrans(vd.trans_fns.constant); 
    String type_name = cursor_type.transCache(vd.trans_fns.type, &vd.types_table);

    return writeConst(vd.out, type_name, name, vd_const.val.str_view());
  };
}

