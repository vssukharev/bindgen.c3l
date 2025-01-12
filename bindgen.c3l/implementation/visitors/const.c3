
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
  @pool()
  {
    ConstVisitData* vd = (ConstVisitData*) client_data;

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
          trans_token_str = token_str.tempTrans(vd.g.trans_fns.constant);

        case clang::TOKEN_LITERAL:
          trans_token_str = token_str.tempTransIntSuffix();

        default:
          trans_token_str = token_str;
      }

      vd.val.append(trans_token_str);
    };
   
    return clang::CHILD_VISIT_BREAK;
  };
}
