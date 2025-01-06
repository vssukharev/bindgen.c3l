
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
  CXSourceRange sr = getTrueCursorExtent(cursor);

  CXToken* tokens;
  uint tokens_len;
  
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
    
    vd.val.append(trans_token_str);
  }
 
  return clang::CHILD_VISIT_BREAK;
}
