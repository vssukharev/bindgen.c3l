
module bindgen::bg @private;
import clang, std::io;

const ANSI_RED = "\e[31m";
const ANSI_GREEN = "\e[32m";
const ANSI_YELLOW = "\e[33m";
const ANSI_NONE = "\e[0m";

macro log(String str = "", ...) 
{
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

macro String CXString.toString(self) => 
  clang::getCString(self).str_view();

macro String String.normType(self) => 
  self.strip("struct ");

<*
 Tranlsates 'self' string and returns the new 
 translated one (or copy of original string).
*>
macro String String.trans(self, BGTransFn fun) =>
  fun != null ? fun(self) : self.copy();

<*
 Tranlsates 'self' string, returns the new 
 translated one (or copy of original string)
 and caches it into translation table.
*>
macro String String.transCached(
  val, 
  BGTransFn fun, 
  TransTable* table)
{
  String translated;
  
  if (try cached = (*table)[val]) 
  {
    translated = cached;
  } 
  else 
  {
    translated = val.trans(fun);
    table.set(val, translated);
  }

  return translated;
}

