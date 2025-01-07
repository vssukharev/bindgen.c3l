
module bindgen::bg @private;
import std::io, clang;

<*
 Writes macro definition to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeMacro(
  File* out,
  String translated_name,
  String value)
@maydiscard
{
  return io::fprintfn(out, "\nconst %s = %s;", translated_name, value);
}

