
module bindgen::bg @private;
import std::io, clang;

<*
 Visits enum values
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
  vd.vals.names[vd.current] = cursor_str.transCache(vd.g.trans_fns.constant, &vd.g.consts_table); 

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
  @pool()
  {
    EnumValVisitData* vd = (EnumValVisitData*) client_data;

    CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
    CXSourceRange sr = getTrueCursorExtent(cursor);

    CXToken* tokens; uint tokens_len;
    clang::tokenize(tu, sr, &tokens, &tokens_len);
    defer clang::disposeTokens(tu, tokens, tokens_len);
 
    @iterateTokens(tokens[:tokens_len], tu; String token_str, CXTokenKind token_kind)
    {
      String trans_token_str;

      switch (token_kind)
      {
        case clang::TOKEN_IDENTIFIER:
          trans_token_str = token_str.transCache(vd.g.trans_fns.constant, &vd.g.consts_table);

        case clang::TOKEN_LITERAL:
          trans_token_str = token_str.tempTransIntSuffix();

        default:
          trans_token_str = token_str;
      }
      
      vd.rhs.append_chars(trans_token_str);
    };
   
    return clang::CHILD_VISIT_BREAK;
  };
}


