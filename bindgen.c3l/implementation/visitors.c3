
module bindgen::bg @private;
import clang;

struct VisitDataGlobal
{
  BGTransCallbacks* trans_callbacks;
}

struct VisitDataFunc
{
  BGVarTransFn fn_var;
  BGTypeTransFn fn_type;
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

  // Handle function declaration
  if (cursor_kind == clang::CURSOR_FUNCTION_DECL)
  {
    cursor_name = getFuncName(cursor_name);
    VisitDataFunc visit_data_func = {
      .fn_var = visit_data.trans_callbacks.variable, 
      .fn_type = visit_data.trans_callbacks.type, 
    };
    clang::visitChildren(cursor, &visitorFunc, (CXClientData) &visit_data_func);
  }

  log("(%s) : %s", cursor_kind_name, cursor_name);

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

  log("%s %s", cursor_type_name, cursor_name);

  return clang::CHILD_VISIT_CONTINUE;
}
