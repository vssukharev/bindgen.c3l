
module bindgen::bg @private;
import std::io, clang;

<*
 Translates alias declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_TYPEDEF_DECL "Cursor must point to typedef declaration"
 @returns "Number of bytes written"
*>
fn usz! transWriteTypedef(GlobalVisitData* vd, CXCursor cursor) @maydiscard
{
  CXType type = clang::getCursorType(cursor);
  CXType under_type = clang::getTypedefDeclUnderlyingType(cursor);

  @pool()
  {
    String type_name = type.transCache(vd.trans_fns.type, &vd.types_table);

    if (under_type.kind == clang::TYPE_POINTER && clang::getPointeeType(under_type).kind == clang::TYPE_FUNCTION_PROTO)
    {
      // Translate pointer to function
      FuncVisitData vd_func = {
        .g = vd,
        .allocator = allocator::temp(),
      };

      vd_func.params.temp_init(4);
      
      CXType ret_type = clang::getResultType(clang::getPointeeType(under_type));
      String ret_type_name = ret_type.transCache(vd.trans_fns.type, &vd.types_table);

      // Translate function parameters and store them into vd_struct.fields
      clang::visitChildren(cursor, &visitorFunc, (CXClientData) &vd_func);

      return writeFuncTypedef(vd.out, type_name, ret_type_name, vd_func.params.array_view());
    }
    else
    {
      // Translate alias
      String under_type_name = under_type.transCache(vd.trans_fns.type, &vd.types_table);

      return type_name != under_type_name 
        ? writeAliasTypedef(vd.out, type_name, under_type_name)
        : 0; // do not write if aliases are equal
    }
  };
}

