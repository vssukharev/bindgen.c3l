
module bindgen::bg @private;
import std::io, clang;

<*
 Intended to visit rhs values of global constants, 
 translating only identifiers
*>
fn CXChildVisitResult visitorConst(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  ConstVisitData* vd = (ConstVisitData*) client_data;

  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
  CXSourceRange sr = clang::getCursorExtent(cursor);
  CXToken* tokens;
  uint tokens_len;
  
  clang::tokenize(tu, sr, &tokens, &tokens_len);
  defer clang::disposeTokens(tu, tokens, tokens_len);
  
  for (uint i; i < tokens_len; ++i)
  {
    CXString token_spell = clang::getTokenSpelling(tu, tokens[i]);
    defer clang::disposeString(token_spell);
    String token_str = token_spell.toString();
    CXTokenKind token_kind = clang::getTokenKind(tokens[i]);

    // TODO: get rid of mem leak
    String trans_token_str = token_kind == clang::TOKEN_IDENTIFIER 
      ? token_str.transCached(vd.g.trans_fns.constant, &vd.g.consts_table)
      : token_str.copy();
    
    vd.val.append(trans_token_str);

    // log("%s", token_str, indent: 1);
  }
 
  return clang::CHILD_VISIT_BREAK;
}
