
module bindgen::bg @private;
import std::io;

<*
 Writes module name to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeHeader(
  File* out,
  String module_name)
@maydiscard
{
  return io::fprintfn(out, "\nmodule %s;\n", module_name);
}


