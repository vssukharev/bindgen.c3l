
module bgimpl::err;
import bindgen::bg, bgimpl;
import clang, std::io;


const ANSI_RED = "\e[31m";
const ANSI_GREEN = "\e[32m";
const ANSI_YELLOW = "\e[33m";
const ANSI_NONE = "\e[0m";


<*
 Debug helper macro.
 Writes str to stdout with special format.
*>
macro void log(
  String str = "", 
  ..., 
  usz indent = 0) 
{
  for (usz i; i < indent; ++i) {
    io::eprintf("  ");
  }
  io::eprintf("%s[%s]%s : ", ANSI_GREEN, $$FUNC, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 


<*
 Debug helper macro.
 Writes str to out with special format.
*>
macro void flog(
  File* out, 
  String str = "", 
  ...) 
{
  io::fprintf(out, "// [%s] : ", $$FUNC)!!;
  io::fprintfn(out, str, $vasplat)!!;
} 


<*
 If !no_verbose, writes str to stdout
 in warning format
*>
macro void warn(
  bool no_verbose, 
  String str = "", 
  ...) 
{
  if (!no_verbose) {
    io::eprintf("%sWarning%s : ", ANSI_YELLOW, ANSI_NONE);
    io::eprintfn(str, $vasplat);
  }
}


<*
 Writes str to stdout
 in info format
*>
macro void info(
  String str = "", 
  ...) 
{
  io::eprintf("%sInfo%s : ", ANSI_GREEN, ANSI_NONE);
  io::eprintfn(str, $vasplat);
} 


<*
 Writes str to stdout
 in error format
*>
macro void erro(
  String str = "", 
  ...) 
{
  io::eprintf("%sError%s : ", ANSI_RED, ANSI_NONE);
  io::eprintfn(str, $vasplat);
}


<*
 Writes str to stdout
 in diagnostic format
*>
macro void diag(
  String file, 
  CUInt line, 
  CUInt col, 
  String str, 
  ...)
{
  io::eprintf("%sError at %s:%d:%d%s : ", ANSI_RED, file, line, col, ANSI_NONE);
  io::eprintfn(str, $vasplat);
}


