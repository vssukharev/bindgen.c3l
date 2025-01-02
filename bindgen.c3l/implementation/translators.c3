
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


<*
 Translates structure declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_STRUCT_DECL "Cursor must point to structure declaration"
 @returns "Number of bytes written"
*>
fn usz! transStruct(
  GlobalVisitData* vd,
  CXCursor cursor)
@maydiscard
{
  @pool() {
    StructVisitData vd_struct = {
      .g = vd,
    };

    vd_struct.fields.temp_init(4);
  
    // Translate function parameters and store them into vd_struct.fields
    clang::visitChildren(cursor, &visitorStruct, (CXClientData) &vd_struct);
    
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
  CXCursor cursor) @maydiscard
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

