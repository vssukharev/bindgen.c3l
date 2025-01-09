
module bindgen::bg @private;
import std::io, clang;

<*
 Writes structure to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeStruct(
  File* out,
  VarDecl[] fields,
  String translated_name) 
@maydiscard
{
  usz acc;

  acc += io::fprintfn(out, "struct %s {", translated_name)!;
  foreach (p : fields) 
  {
    acc += io::fprintfn(out, "  %s %s;", p.type, p.name)!;
  }
  acc += io::fprintfn(out, "}\n")!;
  
  return acc;
}
