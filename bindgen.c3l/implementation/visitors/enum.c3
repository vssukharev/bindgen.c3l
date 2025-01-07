
module bindgen::bg @private;
import std::io, clang;

<*

*>
fn CXChildVisitResult visitorEnum(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  EnumVisitData* vd = (EnumVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = cursor_spell.toString();
  vd.vals.names[vd.current] = cursor_str.transCached(vd.g.trans_fns.constant, &vd.g.consts_table); 

  EnumValVisitData vd_val = {
    .g = vd.g,
    .rhs = vd.vals.rhses + vd.current,
  };

  clang::visitChildren(cursor, &visitorEnumValue, (CXClientData) &vd_val);

  // If we get empty rhs, evaluate value
  if (vd_val.rhs.str_view() == "")
  {
    if (vd.is_unsigned)
    {
      CULongLong ival = clang::getEnumConstantDeclUnsignedValue(cursor);
      vd_val.rhs.appendf("%s", ival);
    }
    else
    {
      CLongLong ival = clang::getEnumConstantDeclValue(cursor);
      vd_val.rhs.appendf("%s", ival);
    }
  }

  ++vd.current;

  return clang::CHILD_VISIT_CONTINUE;
}

<*
*>
fn CXChildVisitResult visitorEnumValue(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  EnumValVisitData* vd = (EnumValVisitData*) client_data;

  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
  CXSourceRange sr = getTrueCursorExtent(cursor);

  CXToken* tokens; uint tokens_len;
  clang::tokenize(tu, sr, &tokens, &tokens_len);
  defer clang::disposeTokens(tu, tokens, tokens_len);
  
  foreach (&t : tokens[:tokens_len])
  {
    CXString token_spell = clang::getTokenSpelling(tu, *t);
    defer clang::disposeString(token_spell);
    String token_str = token_spell.toString();
    CXTokenKind token_kind = clang::getTokenKind(*t);

    // TODO: get rid of memory leak
    String trans_token_str = token_kind == clang::TOKEN_IDENTIFIER 
      ? token_str.transCached(vd.g.trans_fns.constant, &vd.g.consts_table)
      : token_str.copy();
    
    vd.rhs.append_chars(trans_token_str);
  }
 
  return clang::CHILD_VISIT_BREAK;
}


