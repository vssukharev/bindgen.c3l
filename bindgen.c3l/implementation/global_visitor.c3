
module bindgen::bg @private;
import clang, std::io, std::collections::list;

struct GlobalVisitData
{
  BGTransCallbacks* trans_callbacks;
}

<*
 @param [&in] client_data "Must be a valid pointer to VisitDataGlobal"
*>
fn CXChildVisitResult visitorGlobal(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  GlobalVisitData* visit_data = (GlobalVisitData*) client_data;

  CXCursorKind cursor_kind = clang::getCursorKind(cursor);
  CXString cursor_spell = clang::getCursorSpelling(cursor);
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


  @pool() {
    // Handle function declaration
    if (cursor_kind == clang::CURSOR_FUNCTION_DECL)
    {
      String func_name_old = cursor_name;
      String func_name_new = visit_data.trans_callbacks.function == null ? func_name_old : visit_data.trans_callbacks.function(func_name_old);
      
      FuncVisitData visit_data_func = {
        .var_fn = visit_data.trans_callbacks.variable, 
        .type_fn = visit_data.trans_callbacks.type,
      };

      visit_data_func.params.list.temp_init(4);

      CXType ret_cxtype = clang::getCursorResultType(cursor);
      CXString ret_type_spelling = clang::getTypeSpelling(ret_cxtype);
      defer clang::disposeString(ret_type_spelling);
      String ret_type = ret_type_spelling.convertToType();

      clang::visitChildren(cursor, &visitorFunc, (CXClientData) &visit_data_func);
      io::printfn("fn %s %s(%s) @extern(\"%s\");", ret_type, func_name_new, visit_data_func.params, func_name_old);
    }

    return clang::CHILD_VISIT_CONTINUE;
  };
}

