
module bindgen::impl::vtor @private;
import bindgen::bg, bindgen::impl @public;
import std::io, clang;

const EMPTY_TOKENS @local = "";

<*
 Global visitor
*>
fn CXChildVisitResult global(
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

  // If cursor file is not equal to the parsed one,
  // it's either inside of an included header or
  // macro defined by compiler so that it returns 
  // null pointer to a file
  if (!clang::isEqual_File(cursor_file, vd.cxfile))
  {
    return clang::CHILD_VISIT_CONTINUE; 
  }

  // TODO: make non-const global variables translation
  switch (cursor_kind)
  {
    case clang::CURSOR_FUNCTION_DECL: ttor::func(vd, cursor);
    case clang::CURSOR_STRUCT_DECL: ttor::structDecl(vd, cursor);
    case clang::CURSOR_TYPEDEF_DECL: ttor::typedefDecl(vd, cursor);
    case clang::CURSOR_VAR_DECL: ttor::constDecl(vd, cursor);
    case clang::CURSOR_ENUM_DECL: ttor::enumDecl(vd, cursor);
    case clang::CURSOR_MACRO_DEFINITION: ttor::macroDef(vd, cursor);
    case clang::CURSOR_UNION_DECL: ttor::unionDecl(vd, cursor);
  }

  return clang::CHILD_VISIT_CONTINUE;
}


<*
 Intended to visit rhs values of global constants, 
 translating only identifiers. Regular (not enum)
 constants have two children: their type and their value,
 so we have to skip their type to the their value.
*>
fn CXChildVisitResult constDecl(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  ConstVisitData* vd = (ConstVisitData*) client_data;
  defer ++vd.current;
  
  if (vd.current == 0)
  {
    return clang::CHILD_VISIT_CONTINUE;
  }

  return vtor::enumConstDecl(cursor, parent, client_data);
}

<*
 Intended to visit enum constants. It is like a subset
 of vtor::constDecl which doesn't have the first child
 as type.
*>
fn CXChildVisitResult enumConstDecl(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  @pool()
  {
    ConstVisitData* vd = (ConstVisitData*) client_data;

    CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
    CXSourceRange sr = misc::getTrueCursorExtent(cursor);

    CXToken* tokens;
    uint tokens_len;

    String trans_tokens = trans::tokensUnderCursor(tmem, cursor, &vd.g.trans_fns) ?? EMPTY_TOKENS;
    vd.val.append(trans_tokens);
   
    return clang::CHILD_VISIT_CONTINUE;
  };
}

fn CXChildVisitResult enumDecl(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  EnumVisitData* vd = (EnumVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = misc::convStr(cursor_spell);
  
  String? trans_cursor_str = trans::apply(cursor_str, vd.g.trans_fns.constant); // TODO: get rid of leak 

  if (catch trans_cursor_str)
  {
    err::warn("Enum value '%s' is ignored", cursor_str);
    return clang::CHILD_VISIT_CONTINUE;
  }
  
  vd.vals.names[vd.current] = trans_cursor_str;

  ConstVisitData vd_const = {
    .g = vd.g,
  };

  vd_const.val.init(mem);
  defer vd_const.val.free();

  clang::visitChildren(cursor, &vtor::enumConstDecl, (CXClientData) &vd_const);

  // If we get empty rhs, evaluate value
  if (vd_const.val.str_view() == EMPTY_TOKENS)
  {
    if (vd.is_unsigned)
    {
      CULongLong ival = clang::getEnumConstantDeclUnsignedValue(cursor);
      vd_const.val.appendf("%s", ival);
    }
    else
    {
      CLongLong ival = clang::getEnumConstantDeclValue(cursor);
      vd_const.val.appendf("%s", ival);
    }
  }

  vd.vals.rhses[vd.current] = vd_const.val.copy_str(mem); // TODO: get rid of leak

  ++vd.current;
  return clang::CHILD_VISIT_CONTINUE;
}

<*
 Considered to visit function parameters
*>
fn CXChildVisitResult func(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FuncVisitData* vd = (FuncVisitData*) client_data;

  // If CURSOR_TYPE_REF is occured as function, child, it means
  // that it's return type of a function pointer, for instance
  if (clang::getCursorKind(cursor) == clang::CURSOR_TYPE_REF)
  {
    return clang::CHILD_VISIT_CONTINUE;
  }

  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String name_str = misc::convStr(name_spell); 
  String? trans_name_str = trans::apply(name_str, vd.g.trans_fns.variable, vd.allocator);

  if (catch trans_name_str)
  {
    CXString parent_spell = clang::getCursorSpelling(parent);
    defer clang::disposeString(parent_spell);
    String parent_str = misc::convStr(parent_spell);

    err::warn("Can't translate function/function type '%s' as it's parameter '%s' is ignored", parent_str, name_str);
    return clang::CHILD_VISIT_BREAK;
  }

  CXType type = clang::getCursorType(cursor);
  String? trans_type_str = trans::ctype(type, vd.g.trans_fns.type, &vd.g.types_table);
  
  if (catch trans_type_str)
  {
    CXString type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String type_str = misc::convStr(type_spell);

    CXString parent_spell = clang::getCursorSpelling(parent);
    defer clang::disposeString(parent_spell);
    String parent_str = misc::convStr(parent_spell);

    err::warn("Can't translate function/function type '%s' as it's parameter '%s' has type '%s' which is ignored", parent_str, name_str, type_str);
    return clang::CHILD_VISIT_BREAK;
  }

  vd.params.push({trans_type_str, trans_name_str});

  return clang::CHILD_VISIT_CONTINUE;
}

<*
 Visits fields of either struct or union
*>
fn CXChildVisitResult fields(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FieldsVisitData* vd = (FieldsVisitData*) client_data;

  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String name_str = misc::convStr(name_spell);

  CXType type = clang::getCursorType(cursor);
  
  vd.fields.widths[vd.current] = clang::getFieldDeclBitWidth(cursor);

  String? res_name = trans::apply(name_str, vd.g.trans_fns.variable, vd.allocator);

  if (catch res_name)
  {
    err::warn("Field (variable) '%s' is ignored", name_str);
    return clang::CHILD_VISIT_BREAK;
  }

  String? res_type = trans::ctype(type, vd.g.trans_fns.type, &vd.g.types_table);
  
  if (catch res_type)
  {
    CXString type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String type_str = misc::convStr(type_spell);

    CXString parent_spell = clang::getCursorSpelling(parent);
    defer clang::disposeString(parent_spell);
    String parent_str = misc::convStr(parent_spell);

    err::warn("Can't translate struct/union '%s' as it's return type '%s' is ignored", parent_str, type_str);
    return clang::CHILD_VISIT_BREAK;
  }
  

  vd.fields.vals[vd.current] = {
    .type = res_type,
    .name = res_name,
  };

  ++vd.current;
  return clang::CHILD_VISIT_CONTINUE;
}

