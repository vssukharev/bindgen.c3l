
module bindgen::bg @private;
import std::io, clang;

<*

*>
fn CXChildVisitResult visitorFunc(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FuncVisitData* vd = (FuncVisitData*) client_data;

  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String trans_name_str = name_spell.toString().newTrans(vd.g.trans_fns.variable, vd.allocator);

  CXString type_spell = clang::getTypeSpelling(clang::getCursorType(cursor));
  defer clang::disposeString(type_spell);
  String trans_type_str = type_spell.toString().normType().transCache(vd.g.trans_fns.type, &vd.g.types_table);

  vd.params.push({trans_type_str, trans_name_str});

  return clang::CHILD_VISIT_CONTINUE;
}
