
module bindgen::misc @private;
import bindgen::trans @public;
import clang, std::io;

<*
 Behaviour of clang::getCursorExtent is a bit broken. If some macro
 is expanded under the following cursor, beginning of the given range
 will point to the macro definition. Apparently, clang::getExpansionLocation
 fixes that bug. I love libclang :)
*>
fn CXSourceRange getTrueCursorExtent(CXCursor cursor)
{
  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
  CXSourceRange sr = clang::getCursorExtent(cursor);
  CXSourceLocation sl_begin = clang::getRangeStart(sr);    
  CXSourceLocation sl_end = clang::getRangeEnd(sr);
  CXFile file; CUInt offset; 
  clang::getExpansionLocation(sl_begin, &file, null, null, &offset);
  sl_begin = clang::getLocationForOffset(tu, file, offset); 
  sr = clang::getRange(sl_begin, sl_end);

  return sr;
}

<*
 Literally iterates through CXToken[] automatically converting them to strings it
*>
macro @iterateTokens(CXToken[] tokens, CXTranslationUnit tu; @body(CXToken* token, String token_str))
{
  foreach (&t : tokens)
  {
    CXString token_spell = clang::getTokenSpelling(tu, *t);
    defer clang::disposeString(token_spell);
    String token_str = trans::convStr(token_spell);

    @body(t, token_str);
  }
}

