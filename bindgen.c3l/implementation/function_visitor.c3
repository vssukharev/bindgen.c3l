
module bindgen::bg @private;
import clang, std::io, std::collections::list;

struct FuncVisitData
{
  FuncParams params;
  BGVarTransFn var_fn;
  BGTypeTransFn type_fn;
}

struct FuncParams (Printable)
{
  List(<FuncParam>) list; 
}

struct FuncParam
{
  String name;
  String type;
}

fn usz! FuncParams.to_format(&self, Formatter* formatter) @dynamic
{
  usz accum;
  foreach (usz i, &elem : self.list)
  {
    accum += formatter.printf("%s %s", elem.type, elem.name)!;
    if (i < self.list.len() - 1) accum += formatter.printf(", ")!;
  }
  return accum;
}

<*
 @param [in] client_data "Must be a valid pointer to VisitDataFunc"
*>
fn CXChildVisitResult visitorFunc(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FuncVisitData* visit_data = (FuncVisitData*) client_data;

  CXString cursor_spell = clang::getCursorDisplayName(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_name = cursor_spell.convert().copy();

  CXType cursor_type = clang::getCursorType(cursor);
  CXString cursor_type_spell = clang::getTypeSpelling(cursor_type);
  defer clang::disposeString(cursor_type_spell);
  String cursor_type_name = cursor_type_spell.convertToType().copy();

  // TODO: implement
  // if (visit_data.fn_var != null) visit_data.fn_var(cursor_name);
  // if (visit_data.fn_type != null) visit_data.fn_type(cursor_type_name);
 
  visit_data.params.list.push({cursor_name, cursor_type_name});

  log("%s [%s]", cursor_name, cursor_type_name);

  return clang::CHILD_VISIT_CONTINUE;
}



