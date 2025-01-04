
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
  
  // Behaviour of clang::getCursorExtent is a bit broken. If some macro
  // is expanded under the following cursor, beginning of the given range
  // will point to the macro definition. Apparently, clang::getExpansionLocation
  // fixes that bug. I love libclang :)
  {
    CXSourceLocation sl_begin = clang::getRangeStart(sr);    
    CXSourceLocation sl_end = clang::getRangeEnd(sr);
    CXFile file; CUInt offset; 
    clang::getExpansionLocation(sl_begin, &file, null, null, &offset);
    sl_begin = clang::getLocationForOffset(tu, file, offset); 
    sr = clang::getRange(sl_begin, sl_end);
  }

  CXToken* tokens;
  uint tokens_len;
  
  clang::tokenize(tu, sr, &tokens, &tokens_len);
  defer clang::disposeTokens(tu, tokens, tokens_len);
  
  foreach (t : tokens[:tokens_len])
  {
    CXString token_spell = clang::getTokenSpelling(tu, t);
    defer clang::disposeString(token_spell);
    String token_str = token_spell.toString();
    CXTokenKind token_kind = clang::getTokenKind(t);

    // TODO: get rid of memory leak
    String trans_token_str = token_kind == clang::TOKEN_IDENTIFIER 
      ? token_str.transCached(vd.g.trans_fns.constant, &vd.g.consts_table)
      : token_str.copy();
    
    vd.val.append(trans_token_str);
  }
 
  return clang::CHILD_VISIT_BREAK;
}
