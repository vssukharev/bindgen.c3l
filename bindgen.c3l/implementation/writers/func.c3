
module bindgen::bg @private;
import std::io, clang;

<*
 Writes function to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeFunc(
  File* out,
  VarDecl[] params,
  String return_type,
  String original_name,
  String translated_name) 
@maydiscard
{
  usz acc;

  acc += io::fprintfn(out, "\nfn %s %s(", return_type, translated_name)!;
  foreach (i, p : params) 
  {
    acc += io::fprintf(out, "  %s %s", p.type, p.name)!;
    if (i < params.len - 1) acc += io::fprintn(out, ", ")!;
  }
  acc += io::fprintf(out, ")\n@extern(\"%s\");\n", original_name)!;

  return acc;
}
