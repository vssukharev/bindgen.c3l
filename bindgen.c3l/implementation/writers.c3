
module bindgen::bg;
import clang, std::io;

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

  acc += io::fprintfn(out, "fn %s %s(", return_type, translated_name)!;
  foreach (i, p : params) 
  {
    acc += io::fprintf(out, "  %s %s", p.type, p.name)!;
    if (i < params.len - 1) acc += io::fprintn(out, ", ")!;
  }
  acc += io::fprintf(out, ")\n@extern(\"%s\");\n", original_name)!;

  return acc;
}


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
  acc += io::fprintfn(out, "}")!;
  
  return acc;
}


<*
 Writes function pointer typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeFuncTypedef(
  File* out) 
  @maydiscard
{
  usz acc;

  acc += io::fprintfn(out, "This is function typedef")!;
  
  return acc;
}


<*
 Writes aliasing typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! writeAliasTypedef(
  File* out)
  @maydiscard
{
  usz acc;
  
  acc += io::fprintfn(out, "This is aliasing typedef")!;

  return acc;
}


