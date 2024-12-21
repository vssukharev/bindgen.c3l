
module bindgen::bg @private;
import clang, std::io;

const ANSI_RED = "\e[31m";
const ANSI_GREEN = "\e[32m";
const ANSI_NONE = "\e[0m";

macro log(String str = "", ...) 
{
  io::eprintf("%s[%s]%s : ", ANSI_GREEN, $$FUNC, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 

macro void! processErrCode(CXErrorCode code)
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

macro String getStringCursor(CXString str) => clang::getCString(str).str_view();

