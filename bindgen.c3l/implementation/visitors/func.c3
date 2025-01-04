
module bindgen::bg @private;
import std::io, clang;

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
