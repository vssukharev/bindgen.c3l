
module bindgen::bg @private;
import std::io, clang;

<*
 Translates global constant declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_VAR_DECL "Cursor must point to variable declaration"
 @returns "Number of bytes written"
*>
fn usz! transConst(
  GlobalVisitData* vd,
  CXCursor cursor)
@maydiscard
{
  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  
  CXType cursor_type = clang::getCursorType(cursor);
  CXString cursor_type_spell = clang::getTypeSpelling(cursor_type);
  defer clang::disposeString(cursor_type_spell);

  String name = cursor_spell.toString().transCached(vd.trans_fns.constant, &vd.consts_table); 
  String type_name = cursor_type_spell.toString().normType().transCached(vd.trans_fns.variable, &vd.types_table);

  ConstVisitData vd_const = {
    .g = vd,
  };

  vd_const.val.new_init(10);

  // Visit rhs of var declaration and translate 
  // there everything, that is identifier
  clang::visitChildren(cursor, &visitorConst, (CXClientData) &vd_const);

  return writeConst(vd.out, type_name, name, vd_const.val.str_view());
}

