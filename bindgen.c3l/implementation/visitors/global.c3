
module bindgen::bg @private;
import std::io, clang;

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

  // TODO: make non-const global variables translation
  switch (cursor_kind)
  {
    case clang::CURSOR_FUNCTION_DECL: transFunc(vd, cursor);
    case clang::CURSOR_STRUCT_DECL: transStruct(vd, cursor);
    case clang::CURSOR_TYPEDEF_DECL: transTypedef(vd, cursor);
    case clang::CURSOR_VAR_DECL: transConst(vd, cursor);
    case clang::CURSOR_ENUM_DECL: transEnum(vd, cursor);
    case clang::CURSOR_MACRO_DEFINITION: transMacro(vd, cursor);
  }

  return clang::CHILD_VISIT_CONTINUE;
}

