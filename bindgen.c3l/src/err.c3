
module bgimpl::err;
import bindgen::bg, bgimpl;
import clang, std::io;


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
  io::eprintf("%s[%s]%s : ", Ansi.GREEN, $$FUNC, Ansi.RESET);
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
    io::eprintf("%sWarning%s : ", Ansi.YELLOW, Ansi.RESET);
    io::eprintfn(str, $vasplat);
  }
}


<*
 If !no_verbose, writes str to stdout
 in info format
*>
macro void info(
  bool no_verbose,
  String str = "", 
  ...) 
{
  if (!no_verbose) {
    io::eprintf("%sInfo%s : ", Ansi.GREEN, Ansi.RESET);
    io::eprintfn(str, $vasplat);
  }
} 


<*
 Writes str to stdout
 in error format
*>
macro void erro(
  String str = "", 
  ...) 
{
  io::eprintf("%sError%s : ", Ansi.RED, Ansi.RESET);
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
  io::eprintf("%sError at %s:%d:%d%s : ", Ansi.RED, file, line, col, Ansi.RESET);
  io::eprintfn(str, $vasplat);
}


