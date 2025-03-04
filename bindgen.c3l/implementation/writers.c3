
module bindgen::wter @private;
import bindgen::bg @public;
import std::io, clang;

<*
 Writes aliasing typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! typedefAlias(
  File* out,
  String translated_name,
  String underlying_name) 
@maydiscard
{
  return io::fprintfn(out, "def %s = %s;", translated_name, underlying_name);
}

<*
 Writes distinct typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! typedefDist(
  File* out,
  String translated_name,
  String underlying_name) 
@maydiscard
{
  return io::fprintfn(out, "distinct %s = %s;", translated_name, underlying_name);
}

<*
 Writes function pointer typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz! typedefFunc(
  File* out,
  String translated_name,
  String return_type,
  VarDecl[] params)
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
  acc += io::fprintn(out, ");\n")!;
  
  return acc;
}

<*
 Writes global constant to 'out'
 @returns "Number of bytes written"
*>
fn usz! constant(
  File* out,
  String translated_type,
  String translated_name,
  String value)
@maydiscard
{
  return io::fprintfn(out, "const %s %s = %s;", translated_type, translated_name, value);
}

<*
 Writes enum with values to 'out'
 @returns "Number of bytes written"
*>
fn usz! enumeration(
  File* out,
  String name,
  String type,
  EnumVals vals)
@maydiscard
{
  usz acc;
  
  acc += io::fprintfn(out, "distinct %s = inline %s;", name, type)!;
  for (usz i; i < vals.len; ++i)
  {
    acc += io::fprintfn(out, "const %s %s = %s;", name, vals.names[i], vals.rhses[i])!;
  }
  acc += io::fprintn(out)!;
  
  return acc;
}

<*
 Writes function to 'out'
 @returns "Number of bytes written"
*>
fn usz! func(
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
  acc += io::fprintfn(out, ")\n@extern(\"%s\");\n", original_name)!;

  return acc;
}

<*
 Writes module name to 'out'
 @returns "Number of bytes written"
*>
fn usz! moduleHead(
  File* out,
  String module_name)
@maydiscard
{
  return io::fprintfn(out, "\nmodule %s;\n", module_name);
}

<*
 Writes structure to 'out'
 @returns "Number of bytes written"
*>
fn usz! structure(
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

