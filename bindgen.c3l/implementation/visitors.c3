
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

  CXCursorKind cursor_kind = clang::getCursorKind(cursor);

  // Check whether the included file is applicable to us
  CXFile cursor_file;
  clang::getExpansionLocation(clang::getCursorLocation(cursor), &cursor_file, null, null, null);

  // Ignore null file as it might be a macro included by a compiler
  if (cursor_file == null) return clang::CHILD_VISIT_CONTINUE;

  // If file is not equal to ours and it's not permitted, skip it
  if (!clang::isEqual_File(cursor_file, vd.cxfile))
  {
    CXString file_spell = clang::getFileName(cursor_file);
    defer clang::disposeString(file_spell);
    String file_str = misc::convStr(file_spell);

    if (!check::apply(file_str, vd.include_file)) return clang::CHILD_VISIT_CONTINUE; 
  }


  switch (cursor_kind)
  {
    case clang::CURSOR_FUNCTION_DECL: ttor::func(vd, cursor);
    case clang::CURSOR_STRUCT_DECL: ttor::structDecl(vd, cursor);
    case clang::CURSOR_TYPEDEF_DECL: ttor::typedefDecl(vd, cursor);
    case clang::CURSOR_VAR_DECL: ttor::varDecl(vd, cursor);
    case clang::CURSOR_ENUM_DECL: ttor::enumDecl(vd, cursor);
    case clang::CURSOR_MACRO_DEFINITION: ttor::macroDef(vd, cursor);
    case clang::CURSOR_UNION_DECL: ttor::unionDecl(vd, cursor);
  }

  return clang::CHILD_VISIT_CONTINUE;
}

<*
 Intended to visit global or enum constants.
 Note that vd.current ought to be set to the
 quantity of the children.
*>
fn CXChildVisitResult constDecl(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  ConstVisitData* vd = (ConstVisitData*) client_data;

  // When cursor type is a typedef of some other type, one more 
  // child is added to it so skip it
  if (clang::getCursorKind(cursor) == clang::CURSOR_TYPE_REF)
  {
    return clang::CHILD_VISIT_CONTINUE;
  }

  vd.val = trans::tokensUnderCursor(vd.allocator, cursor, &vd.g.trans_fns) ?? EMPTY_TOKENS;

  return clang::CHILD_VISIT_CONTINUE;
}

<*

*>
fn CXChildVisitResult enumDecl(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  EnumVisitData* vd = (EnumVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = misc::convStr(cursor_spell);
  
  String? trans_cursor_str = trans::apply(cursor_str, vd.g.trans_fns.constant, vd.allocator);
  if (catch trans_cursor_str)
  {
    err::warn("Enum value '%s' is ignored", cursor_str);
    return clang::CHILD_VISIT_CONTINUE;
  }
  
  ConstVisitData vd_const = {
    .g = vd.g,
    .allocator = vd.allocator,
  };

  clang::visitChildren(cursor, &vtor::constDecl, (CXClientData) &vd_const);

  // If we get empty rhs, evaluate value
  if (vd_const.val == EMPTY_TOKENS)
  {
    if (vd.is_unsigned)
    {
      CULongLong ival = clang::getEnumConstantDeclUnsignedValue(cursor);
      vd_const.val = string::format(vd.allocator, "%s", ival);
    }
    else
    {
      CLongLong ival = clang::getEnumConstantDeclValue(cursor);
      vd_const.val = string::format(vd.allocator, "%s", ival);
    }
  }

  vd.members.push({trans_cursor_str, vd_const.val});

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

  // If CURSOR_TYPE_REF is occured as function child, it means
  // that it's return type is a function pointer, for instance
  if (clang::getCursorKind(cursor) == clang::CURSOR_TYPE_REF)
  {
    return clang::CHILD_VISIT_CONTINUE;
  }
  
  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String name_str = misc::convStr(name_spell); 

  CXString parent_spell = clang::getCursorSpelling(parent);
  defer clang::disposeString(parent_spell);
  String parent_str = misc::convStr(parent_spell);

  CXType type = clang::getCursorType(cursor);
  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = misc::convStr(type_spell);

  // Make parameter empty if it's ignored
  String trans_name_str = trans::apply(name_str, vd.g.trans_fns.variable, vd.allocator) ?? "";
 
  String? trans_type_str = trans::ctypeWithPFN(cursor, vd.g);
  if (catch trans_type_str)
  {
    err::warn("Can't translate function '%s' as it's parameter type '%s' is ignored", parent_str, type_str);
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

  FieldKind kind = misc::getFieldKind(cursor);

  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String name_str = misc::convStr(name_spell);

  // If the cursor is anonymous record, handle it and go to the next child
  if (clang::isAnonymous_Cursor(cursor))
  {
    vd.prev_anon = cursor;

    FieldsVisitData vd_inner = {
      .g = vd.g,
      .allocator = vd.allocator
    };

    vd_inner.fields.init(vd_inner.allocator);
    
    // Recursively visit records
    if (clang::visitChildren(cursor, &vtor::fields, (CXClientData) &vd_inner) != 0)
    {
      return clang::CHILD_VISIT_BREAK;
    }

    vd.fields.kinds.push(kind);
    switch (kind)
    {
      case STRUCT:
        vd.fields.structs.push({"", vd_inner.fields});
      case UNION:
        vd.fields.unions.push({"", vd_inner.fields});
      default: 
        unreachable();
    }

    return clang::CHILD_VISIT_CONTINUE;
  }

  String? trans_name_str = trans::apply(name_str, vd.g.trans_fns.variable, vd.allocator);
  if (catch trans_name_str)
  {
    err::warn("Field (variable) '%s' is ignored", name_str);
    return clang::CHILD_VISIT_BREAK;
  }

  CXType type = clang::getCursorType(cursor);
  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = misc::convStr(type_spell);

  // Retrieve canonical type as it's the only one which is equatable with anonymous records
  CXType canon_type = clang::getCanonicalType(type);
  CXType prev_type = clang::getCursorType(vd.prev_anon);

  // If previous cursor is anonymous and current is the name of a field
  if (clang::equalTypes(canon_type, prev_type))
  {
    switch (misc::getFieldKind(vd.prev_anon))
    {
      case STRUCT: 
        vd.fields.structs[^1].name = trans_name_str;
      case UNION:
        vd.fields.unions[^1].name = trans_name_str;
      default:
        unreachable();
    }
    return clang::CHILD_VISIT_CONTINUE;
  }

  String? trans_type_str = trans::ctypeWithPFN(cursor, vd.g);
  if (catch trans_type_str)
  {
    CXString parent_spell = clang::getCursorSpelling(parent);
    defer clang::disposeString(parent_spell);
    String parent_str = misc::convStr(parent_spell);

    err::warn("Can't translate struct/union '%s' as it's field type '%s' is ignored", parent_str, type_str);
    return clang::CHILD_VISIT_BREAK;
  }

  // Handle normal and bit fields
  switch (kind)
  {
    case NORMAL:
      vd.fields.norm.push({trans_type_str, trans_name_str});
      vd.fields.kinds.push(NORMAL);
    case BIT:
      CInt width = clang::getFieldDeclBitWidth(cursor);
      vd.fields.bit.push({trans_type_str, trans_name_str, (usz)width});
      vd.fields.kinds.push(BIT);
    // Otherwise it's a declaration of incomplete record    
    default:
      WriteAttrs attrs = valgen::getWriteAttrs(vd.allocator, name_str, vd.g.gen_fns);
      wter::typedefDist(vd.g.out, trans_type_str, "void", attrs);
  }

  return clang::CHILD_VISIT_CONTINUE;
}



