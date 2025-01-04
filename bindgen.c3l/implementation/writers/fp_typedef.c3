
module bindgen::bg @private;
import std::io, clang;

<*
 Writes function pointer typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeFuncTypedef(
  File* out,
  VarDecl[] params,
  String return_type,
  String translated_name) 
@maydiscard
{
  usz acc;

  acc += io::fprintfn(out, "def %s = fn %s(", translated_name, return_type)!;
  foreach (i, p : params) 
  {
    acc += io::fprintf(out, "  %s", p.type)!;
    acc += io::fprintf(out, p.name == "" ? "" : " %s", p.name)!;
    if (i < params.len - 1) acc += io::fprintn(out, ", ")!;
  }
  acc += io::fprintn(out, ");")!;
  
  return acc;
}
