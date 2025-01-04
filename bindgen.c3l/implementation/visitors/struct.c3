
module bindgen::bg @private;
import std::io, clang;

fn CXChildVisitResult visitorStruct(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  StructVisitData* vd = (StructVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String original_name = cursor_spell.toString();

  CXString cursor_type_spell = clang::getTypeSpelling(clang::getCursorType(cursor));
  defer clang::disposeString(cursor_type_spell);
  String original_type_name = cursor_type_spell.toString().normType();

  String translated_name = original_name.trans(vd.g.trans_fns.variable);
  String translated_type_name = original_type_name.transCached(vd.g.trans_fns.type, &vd.g.types_table);

  vd.fields.push({translated_type_name, translated_name});

  return clang::CHILD_VISIT_CONTINUE;
}
