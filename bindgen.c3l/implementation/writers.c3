
module bindgen::impl::wter @private;
import bindgen::bg, bindgen::impl @public;
import std::io, clang;

const INDENT = "  ";

<*
 Writes aliasing typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz? typedefAlias(
  File* out,
  String name,
  String underlying_name) 
@maydiscard
{
  return io::fprintfn(out, "\nalias %s = %s;", name, underlying_name);
}

<*
 Writes distinct typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz? typedefDist(
  File* out,
  String name,
  String underlying_name) 
@maydiscard
{
  return io::fprintfn(out, "\ntypedef %s = %s;", name, underlying_name);
}

<*
 Writes function pointer typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz? typedefFunc(
  File* out,
  String name,
  String return_type,
  VarDecl[] params)
@maydiscard
{
  usz? acc;

  acc += io::fprintf(out, "\nalias %s = fn %s(", name, return_type);
  
  if (params.len > 1) acc += io::fprintf(out, "\n");

  foreach (i, p : params) 
  {
    acc += io::fprintf(out, "  %s", p.type);
    if (p.name)
    {
      acc += io::fprintf(out, " %s", p.name);
    }
    if (i < params.len - 1) acc += io::fprintn(out, ", ");
  }

  acc += io::fprintn(out, ");");
  
  return acc;
}

<*
 Writes global constant to 'out'
 @returns "Number of bytes written"
*>
fn usz? constDecl(
  File* out,
  String type,
  String name,
  String value)
@maydiscard
{
  usz? acc;

  if (type == "")
  {
    acc += io::fprintfn(out, "\nconst %s = %s;", name, value);
  }
  else
  {
    acc += io::fprintfn(out, "\nconst %s %s = %s;", type, name, value);
  }

  return acc;
}

<*
 Writes global variable to 'out'
 @returns "Number of bytes written"
*>
fn usz? varDecl(
  File* out,
  String type,
  String name)
@maydiscard
{
  return io::fprintfn(out, "\n%s %s;", type, name);
}

<*
 Writes enum with values to 'out'
 @returns "Number of bytes written"
*>
fn usz? enumDecl(
  File* out,
  String name,
  String type,
  EnumMember[] members)
@maydiscard
{
  usz? acc;
  
  acc += io::fprintfn(out, "\ntypedef %s = inline %s;", name, type);
  foreach (member : members)
  {
    acc += io::fprintfn(out, "const %s %s = %s;", name, member.name, member.val);
  }
  
  return acc;
}

<*
 Writes function to 'out'
 @returns "Number of bytes written"
*>
fn usz? func(
  File* out,
  VarDecl[] params,
  String return_type,
  String original_name,
  String name) 
@maydiscard
{
  usz? acc;

  acc += io::fprintf(out, "\nfn %s %s(", return_type, name);
  if (params.len > 0) acc += io::fprintf(out, "\n");

  foreach (i, p : params) 
  {
    acc += io::fprintf(out, "  %s %s", p.type, p.name);
    if (i < params.len - 1) acc += io::fprintn(out, ", ");
  }
  acc += io::fprintfn(out, ")\n@extern(\"%s\");", original_name);

  return acc;
}

<*
 Writes function to 'out'
 @return "Number of bytes written"
*>
fn usz? funcMacro(
  File* out,
  String[] params,
  String name) 
@maydiscard
{
  usz? acc;

  acc += io::fprintf(out, "\nmacro @%s(", name);
  foreach (i, p : params) 
  {
    acc += io::fprintf(out, "#%s", p);
    if (i < params.len - 1) acc += io::fprint(out, ", ");
  }
  acc += io::fprintfn(out, ") {}");

  return acc;
}

<*
 Writes module name to 'out'
 @returns "Number of bytes written"
*>
fn usz? moduleHead(
  File* out,
  String module_name)
@maydiscard
{
  return io::fprintfn(out, "\nmodule %s;", module_name);
}


fn usz? structDecl(
  File* out,
  String name,
  C3Fields* fields,
  usz indent_level = 0) 
@maydiscard
{
  usz? acc;

  acc += printIndent(out, indent_level);
  
  if (indent_level == 0)
  {
    acc += io::fprintf(out, "\n");
  }

  if (name == "")
  {
    acc += io::fprintfn(out, "struct {");
  }
  else
  {
    acc += io::fprintfn(out, "struct %s {", name);
  }

  acc += wter::fields(out, fields, indent_level + 1);

  acc += printIndent(out, indent_level);
  acc += io::fprintfn(out, "}");
  
  return acc;
}


fn usz? unionDecl(
  File* out,
  String name,
  C3Fields* fields,
  usz indent_level = 0) 
@maydiscard
{
  usz? acc;

  acc += printIndent(out, indent_level);

  if (indent_level == 0)
  {
    acc += io::fprintf(out, "\n");
  }

  if (name == "")
  {
    acc += io::fprintfn(out, "union {");
  }
  else
  {
    acc += io::fprintfn(out, "union %s {", name);
  }

  acc += wter::fields(out, fields, indent_level + 1);

  acc += printIndent(out, indent_level);
  acc += io::fprintfn(out, "}");
  
  return acc;
}


fn usz? fields(
  File* out,
  C3Fields* fields,
  usz indent_level)
{
  usz? acc;

  fields.@foreach(; FieldKind* kind, usz index)
  {
    switch (*kind)
    {
      case NORMAL:
        acc += printIndent(out, indent_level);
        acc += io::fprintfn(out, "%s %s;", fields.norm[index].type, fields.norm[index].name);

      case BIT:
        acc += printIndent(out, indent_level);
        acc += io::fprintfn(out, "bitstruct : %s {", fields.bit[index].under_type)!;

        foreach (BitstructMember bitm : fields.bit[index].fields)
        {
          acc += printIndent(out, indent_level + 1);
          acc += io::fprintfn(out, "%s %s : %s..%s;", bitm.type, bitm.name, bitm.from, bitm.to)!;
        }

        acc += printIndent(out, indent_level);
        acc += io::fprintfn(out, "}")!;

      case STRUCT:
        acc += wter::structDecl(out, fields.structs[index].name, &fields.structs[index].fields, indent_level);

      case UNION:
        acc += wter::unionDecl(out, fields.unions[index].name, &fields.unions[index].fields, indent_level);
    }
  };

  return acc;
}

// ------- Helpers

fn usz? printIndent( 
  File* out, 
  usz indent_level = 1)
{
  usz? acc;
  for (usz i; i < indent_level; ++i) acc += io::fprintf(out, INDENT);
  return acc;
}

