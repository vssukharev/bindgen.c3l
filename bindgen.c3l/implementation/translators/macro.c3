
module bindgen::bg @private;
import std::io, clang;

<*
 Translates macro definition and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_MACRO_DEFINITION "Cursor must point to macro definition"
 @returns "Number of bytes written"
*>
fn usz! transMacro(
  GlobalVisitData* vd,
  CXCursor cursor)
@maydiscard
{
  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = cursor_spell.toString();
  
  if (clang::isMacroFunctionLike_Cursor(cursor))
  {
    warning("Macro %s is function-like, so it must be translated manually.", cursor_str);
    return 0;
  }

  @pool()
  {
    String name = cursor_str.transCached(vd.trans_fns.constant, &vd.consts_table); 

    DString val;
    val.temp_init();

    CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
    CXSourceRange sr = clang::getCursorExtent(cursor);

    CXToken* tokens; uint tokens_len;
    clang::tokenize(tu, sr, &tokens, &tokens_len);
    defer clang::disposeTokens(tu, tokens, tokens_len);
    
    foreach (t : tokens[1..tokens_len-1])
    {
      CXString token_spell = clang::getTokenSpelling(tu, t);
      defer clang::disposeString(token_spell);
      String token_str = token_spell.toString();
      CXTokenKind token_kind = clang::getTokenKind(t);

      if (token_kind == clang::TOKEN_KEYWORD)
      {
        warning("Macro %s comprises C keyword '%s', so it must be translated manually.", cursor_str, token_str);
        return 0;
      }

      // TODO: get rid of memory leak
      String trans_token_str = token_kind == clang::TOKEN_IDENTIFIER 
        ? token_str.transCached(vd.trans_fns.constant, &vd.consts_table)
        : token_str.copy();
   
      if (token_kind == clang::TOKEN_LITERAL)
      {
        trans_token_str = strTransIntSuffix(trans_token_str); // TODO: get rid of leaks
      }
      
      val.append(trans_token_str);
    }

    return writeMacro(vd.out, name, val.str_view());
  };
}

