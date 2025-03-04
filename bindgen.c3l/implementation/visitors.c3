
module bindgen::vtor @private;
import bindgen::bg @public, 
       bindgen::trans @public, 
       bindgen::ttor @public, 
       bindgen::wter @public, 
       bindgen::err @public,
       bindgen::misc @public;
import std::io, clang;

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

  // If we can't find file, definition is included 
  // by compiler so skip it
  if (cursor_file == null) return clang::CHILD_VISIT_CONTINUE;


  if (cursor_kind != clang::CURSOR_MACRO_EXPANSION) 
  {
    err::logf(vd.out, "Kind: %s", cursor_kind);
  }

  // TODO: make non-const global variables translation
  switch (cursor_kind)
  {
    case clang::CURSOR_FUNCTION_DECL: ttor::func(vd, cursor);
    case clang::CURSOR_STRUCT_DECL: ttor::structDecl(vd, cursor);
    case clang::CURSOR_TYPEDEF_DECL: ttor::typedef(vd, cursor);
    case clang::CURSOR_VAR_DECL: ttor::constDecl(vd, cursor);
    case clang::CURSOR_ENUM_DECL: ttor::enumDecl(vd, cursor);
    case clang::CURSOR_MACRO_DEFINITION: ttor::macroDef(vd, cursor);
    case clang::CURSOR_UNION_DECL: ttor::unionDecl(vd, cursor);
    // TODO: union translation
  }

  return clang::CHILD_VISIT_CONTINUE;
}


<*
 Intended to visit rhs values of global constants, 
 translating only identifiers
*>
fn CXChildVisitResult constDecl(
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

    clang::tokenize(tu, sr, &tokens, &tokens_len);
    defer clang::disposeTokens(tu, tokens, tokens_len);
    
    misc::@iterateTokens(tokens[:tokens_len], tu; String token_str, CXTokenKind token_kind)
    {
      String trans_token_str;

      switch (token_kind)
      {
        case clang::TOKEN_IDENTIFIER:
          trans_token_str = trans::tapply(token_str, vd.g.trans_fns.constant);

        case clang::TOKEN_LITERAL:
          trans_token_str = trans::tintSuf(token_str);

        default:
          trans_token_str = token_str;
      }

      vd.val.append(trans_token_str);
    };
   
    return clang::CHILD_VISIT_BREAK;
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
  String cursor_str = trans::convStr(cursor_spell);
  vd.vals.names[vd.current] = trans::apply(cursor_str, vd.g.trans_fns.constant); // TODO: get rid of leak 

  ConstVisitData vd_const = {
    .g = vd.g,
  };

  vd_const.val.init(mem);
  defer vd_const.val.free();

  clang::visitChildren(cursor, &vtor::constDecl, (CXClientData) &vd_const);

  // If we get empty rhs, evaluate value
  if (vd_const.val.str_view() == "")
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

fn CXChildVisitResult func(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FuncVisitData* vd = (FuncVisitData*) client_data;

  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String name_str = trans::convStr(name_spell); 
  String trans_name_str = trans::apply(name_str, vd.g.trans_fns.variable, vd.allocator);

  CXType type = clang::getCursorType(cursor);
  String trans_type_str = trans::ctype(type, vd.g.trans_fns.type, &vd.g.types_table);

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
  StructVisitData* vd = (StructVisitData*) client_data;

  CXString name_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(name_spell);
  String name_str = trans::convStr(name_spell);
  String trans_name_str = trans::apply(name_str, vd.g.trans_fns.variable, vd.allocator);

  CXType type = clang::getCursorType(cursor);
  String trans_type_str = trans::ctype(type, vd.g.trans_fns.type, &vd.g.types_table);
  
  vd.fields.push({trans_type_str, trans_name_str});

  return clang::CHILD_VISIT_CONTINUE;
}

