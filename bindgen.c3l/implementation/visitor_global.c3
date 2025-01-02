
module bindgen::bg @private;
import clang;

fn CXChildVisitResult visitorGlobal(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  GlobalVisitData* vd = (GlobalVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);

  CXCursorKind cursor_kind = clang::getCursorKind(cursor);
  CXString cursor_kind_spell = clang::getCursorKindSpelling(cursor_kind);
  defer clang::disposeString(cursor_kind_spell);

  CXFile cursor_file;
  clang::getExpansionLocation(clang::getCursorLocation(cursor), &cursor_file, null, null, null);

  // If we can't find file, definition is included 
  // by compiler so skip it
  if (cursor_file == null) return clang::CHILD_VISIT_CONTINUE;

  log("(%s) : %s", cursor_kind_spell.toString(), cursor_spell.toString());
  

  switch (cursor_kind)
  {
    case clang::CURSOR_FUNCTION_DECL: transFunc(vd, cursor, &visitorFunc);
    case clang::CURSOR_STRUCT_DECL: transStruct(vd, cursor, &visitorStruct);
    case clang::CURSOR_TYPEDEF_DECL: transTypedef(vd, cursor, &visitorTypedef);
      //  
      // CXType base_type = clang::getTypedefDeclUnderlyingType(cursor);
      // if (base_type.kind == clang::TYPE_POINTER)
      // {
      //   CXString cursor_tk_spell = clang::getTypeKindSpelling(clang::getPointeeType(base_type).kind);
      //   defer clang::disposeString(cursor_tk_spell);
      //   String type_kind = cursor_tk_spell.toString();
      //   log("Type Kind : %s", type_kind);
      // }
  }

  return clang::CHILD_VISIT_CONTINUE;
}

