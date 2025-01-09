
module bindgen::bg @private;
import std::io, clang;

<*
 Writes aliasing typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeAliasTypedef(
  File* out,
  String translated_name,
  String underlying_name) 
@maydiscard
{
  return io::fprintfn(out, "def %s = %s;\n", translated_name, underlying_name);
}
