
module bindgen::bg @private;
import clang, std::io;

struct VisitDataGlobal
{
  BGTransCallbacks* trans_callbacks;
}

struct VisitDataFunc
{
  BGVarTransFn var_fn;
  BGTypeTransFn type_fn;
  BGFuncTransFn func_fn;
  String func_name;
}

<*
 @param [&in] client_data "Must be a valid pointer to VisitDataGlobal"
*>
fn CXChildVisitResult visitorGlobal(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  VisitDataGlobal* visit_data = (VisitDataGlobal*) client_data;

  CXCursorKind cursor_kind = clang::getCursorKind(cursor);
  CXString cursor_spell = clang::getCursorDisplayName(cursor);
  defer clang::disposeString(cursor_spell);
  CXString cursor_kind_spell = clang::getCursorKindSpelling(cursor_kind);
  defer clang::disposeString(cursor_kind_spell);
  String cursor_name = clang::getCString(cursor_spell).str_view();
  String cursor_kind_name = clang::getCString(cursor_kind_spell).str_view();
  
  CXFile cursor_cxfile;
  CXSourceLocation cursor_location = clang::getCursorLocation(cursor);
  clang::getExpansionLocation(cursor_location, &cursor_cxfile, null, null, null);

  // If we can't find file, definition is included by compiler
  // so skip them
  if (cursor_cxfile == null) return clang::CHILD_VISIT_CONTINUE;

  log("(%s) : %s", cursor_kind_name, cursor_name);

  // Handle function declaration
  if (cursor_kind == clang::CURSOR_FUNCTION_DECL)
  {
    cursor_name = getFuncName(cursor_name);
    VisitDataFunc visit_data_func = {
      .var_fn = visit_data.trans_callbacks.variable, 
      .type_fn = visit_data.trans_callbacks.type,
      .func_fn = visit_data.trans_callbacks.function,
      .func_name = cursor_name,
    };
    clang::visitChildren(cursor, &visitorFunc, (CXClientData) &visit_data_func);
    io::printfn("fn void %s() @extern(\"%s\");", visit_data_func.func_name, cursor_name);
  }

  return clang::CHILD_VISIT_CONTINUE;
}

<*
 @param [in] client_data "Must be a valid pointer to VisitDataFunc"
*>
fn CXChildVisitResult visitorFunc(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  VisitDataFunc* visit_data = (VisitDataFunc*) client_data;

  CXString cursor_spell = clang::getCursorDisplayName(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_name = getStringCursor(cursor_spell);

  CXType cursor_type = clang::getCursorType(cursor);
  CXString cursor_type_spell = clang::getTypeSpelling(cursor_type);
  defer clang::disposeString(cursor_type_spell);
  String cursor_type_name = getStringCursor(cursor_type_spell);

  // TODO: implement
  // if (visit_data.fn_var != null) visit_data.fn_var(cursor_name);
  // if (visit_data.fn_type != null) visit_data.fn_type(cursor_type_name);

  if (visit_data.func_fn != null) visit_data.func_name = visit_data.func_fn(visit_data.func_name);

  log("%s [%s]", cursor_name, cursor_type_name);

  return clang::CHILD_VISIT_CONTINUE;
}
