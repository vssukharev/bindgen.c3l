
module bindgen::bg @private;
import std::io, clang;

<*
 Translates macro definition and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_MACRO_DEFINITION "Cursor must point to macro definition"
 @returns "Number of bytes written"
*>
fn usz! transWriteMacro(GlobalVisitData* vd, CXCursor cursor) @maydiscard
{
  CXString macro_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(macro_spell);
  String macro_str = macro_spell.toString();
  
  if (clang::isMacroFunctionLike_Cursor(cursor))
  {
    warning("Macro %s is function-like, skipping...", macro_str);
    return 0;
  }

  @pool()
  {
    String trans_macro_str = macro_str.tempTrans(vd.trans_fns.constant); 

    CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
    CXSourceRange sr = clang::getCursorExtent(cursor); // We don't need to do getTrueCursorExtent as bug is not occured under macro declaration

    CXToken* tokens; uint tokens_len;
    clang::tokenize(tu, sr, &tokens, &tokens_len);
    defer clang::disposeTokens(tu, tokens, tokens_len);
    
    // If macro is empty, it's either guard or something that we might not want to translate
    if (tokens_len <= 1) 
    {
      warning("Macro %s doesn't have value, skipping...", macro_str);
      return 0;
    }

    DString val;
    val.temp_init();
 
    @iterateTokens(tokens[1..tokens_len-1], tu; String token_str, CXTokenKind token_kind)
    {
      String trans_token_str;

      switch (token_kind)
      {
        case clang::TOKEN_KEYWORD:
          warning("Macro %s comprises C keyword '%s', skipping...", macro_str, token_str);
          return 0;

        case clang::TOKEN_IDENTIFIER:
          trans_token_str = token_str.tempTrans(vd.trans_fns.constant);

        case clang::TOKEN_LITERAL:
          trans_token_str = token_str.tempTransIntSuffix();

        default:
          trans_token_str = token_str;
      }
      
      val.append(trans_token_str);
    };

    return writeMacro(vd.out, trans_macro_str, val.str_view());
  };
}

