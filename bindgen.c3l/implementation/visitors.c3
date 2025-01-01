
module bindgen::bg @private;
import clang, std::io, std::collections::list;

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
    case clang::CURSOR_FUNCTION_DECL: writeTransFunc(vd, cursor);
  }

  return clang::CHILD_VISIT_CONTINUE;
}

fn CXChildVisitResult visitorFunc(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FuncVisitData* vd = (FuncVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String translated_name = cursor_spell.toString().trans(vd.g.trans_fns.variable);

  CXString cursor_type_spell = clang::getTypeSpelling(clang::getCursorType(cursor));
  defer clang::disposeString(cursor_type_spell);
  String translated_type_name = cursor_type_spell.toString().normType().transCached(vd.g.trans_fns.type, &vd.g.types_table);

  vd.params.push({translated_type_name, translated_name});

  return clang::CHILD_VISIT_CONTINUE;
}

fn CXChildVisitResult visitorStruct(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  StructVisitData* vd = (StructVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String name = cursor_spell.toString().trans(vd.g.trans_fns.variable);

  CXString cursor_type_spell = clang::getTypeSpelling(clang::getCursorType(cursor));
  defer clang::disposeString(cursor_type_spell);
  String original_type_name = cursor_type_spell.toString().normType().copy();

  return clang::CHILD_VISIT_CONTINUE;
}


