
module bindgen::bg @private;
import std::io, clang;

<*
 Writes global constant to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeConst(
  File* out,
  String translated_type,
  String translated_name,
  String value)
@maydiscard
{
  return io::fprintfn(out, "\nconst %s %s = %s;", translated_type, translated_name, value);
}
