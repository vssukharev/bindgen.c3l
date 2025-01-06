
module bindgen::bg @private;
import clang, std::io;

const ANSI_RED = "\e[31m";
const ANSI_GREEN = "\e[32m";
const ANSI_YELLOW = "\e[33m";
const ANSI_NONE = "\e[0m";

macro log(String str = "", ..., usz indent = 0) 
{
  for (usz i; i < indent; ++i)
  {
    io::eprintf("  ");
  }
  io::eprintf("%s[%s]%s : ", ANSI_GREEN, $$FUNC, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 

macro warning(String str = "", ...) 
{
  io::eprintf("%sWarning%s : ", ANSI_YELLOW, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 

macro void! CXErrorCode.check(code)
{
  switch (code)
  {
    case clang::ERROR_SUCCESS: 
      return;
    case clang::ERROR_FAILURE:
    case clang::ERROR_AST_READ_ERROR:
      return BGParseError.FAILURE?;
    case clang::ERROR_CRASHED:
      return BGParseError.CRASHED?;
    case clang::ERROR_INVALID_ARGUMENTS:
      return BGParseError.INVALID_ARGUMENTS?;
  }
}

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


