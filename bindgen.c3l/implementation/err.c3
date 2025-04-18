
module bindgen::impl::err @private;
import bindgen::bg, bindgen::impl @public;
import clang, std::io;

const ANSI_RED = "\e[31m";
const ANSI_GREEN = "\e[32m";
const ANSI_YELLOW = "\e[33m";
const ANSI_NONE = "\e[0m";

macro void log(String str = "", ..., usz indent = 0) 
{
  for (usz i; i < indent; ++i)
  {
    io::eprintf("  ");
  }
  io::eprintf("%s[%s]%s : ", ANSI_GREEN, $$FUNC, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 

macro void flog(File* out, String str = "", ...) 
{
  io::fprintf(out, "// [%s] : ", $$FUNC)!!;
  io::fprintfn(out, str, $vasplat)!!;
} 

macro void warn(bool no_verbose, String str = "", ...) 
{
  if (!no_verbose)
  {
    io::eprintf("%sWarning%s : ", ANSI_YELLOW, ANSI_NONE);
    io::eprintfn(str, $vasplat);
  }
}

macro void info(String str = "", ...) 
{
  io::eprintf("%sInfo%s : ", ANSI_GREEN, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 

macro void erro(String str = "", ...) 
{
  io::eprintf("%sError%s : ", ANSI_RED, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 

macro void diag(String file, CUInt line, CUInt col, String str, ...)
{
  io::eprintf("%sError at %s:%d:%d%s : ", ANSI_RED, file, line, col, ANSI_NONE);
  io::eprintfn(str, $vasplat);
}

macro void? checkCode(CXErrorCode code)
{
  switch (code)
  {
    case clang::ERROR_SUCCESS: 
      return;

    case clang::ERROR_FAILURE:
    case clang::ERROR_AST_READ_ERROR:
      return bg::CLANG_PARSE_ERROR?;

    case clang::ERROR_CRASHED:
      return bg::CLANG_CRASH?;

    case clang::ERROR_INVALID_ARGUMENTS:
      return bg::INVALID_ARGUMENTS?;
  }
}


