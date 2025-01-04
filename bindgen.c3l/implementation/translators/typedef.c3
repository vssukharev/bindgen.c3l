
module bindgen::bg @private;
import std::io, clang;

<*
 Translates alias declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_TYPEDEF_DECL "Cursor must point to typedef declaration"
 @returns "Number of bytes written"
*>
fn usz! transTypedef(
  GlobalVisitData* vd,
  CXCursor cursor) 
@maydiscard
{
  CXType base_type = clang::getTypedefDeclUnderlyingType(cursor);

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String base_name = cursor_spell.toString().normType().transCached(vd.trans_fns.type, &vd.types_table);

  // Translate pointer to function
  if (base_type.kind == clang::TYPE_POINTER && clang::getPointeeType(base_type).kind == clang::TYPE_FUNCTION_PROTO)
  {
    @pool()
    {
      CXType pointee_type = clang::getPointeeType(base_type);

      FuncVisitData vd_func = {
        .g = vd,
      };

      vd_func.params.temp_init(4);
      
      // Translate function parameters and store them into vd_struct.fields
      clang::visitChildren(cursor, &visitorFunc, (CXClientData) &vd_func);

      CXString ret_type_spelling = clang::getTypeSpelling(clang::getResultType(pointee_type));
      defer clang::disposeString(ret_type_spelling);
      String ret_type = ret_type_spelling.toString().normType().transCached(vd.trans_fns.type, &vd.types_table);

      return writeFuncTypedef(
        vd.out,
        vd_func.params.array_view(),
        ret_type,
        base_name
      );
    };
  }

  // Translate alias
  CXType under_type = clang::getTypedefDeclUnderlyingType(cursor);

  CXString under_type_spell = clang::getTypeSpelling(under_type);
  defer clang::disposeString(under_type_spell);
  String under_type_name = under_type_spell.toString().normType().transCached(vd.trans_fns.type, &vd.types_table);
  
  return writeAliasTypedef(
    vd.out,
    base_name,
    under_type_name
  );
}

