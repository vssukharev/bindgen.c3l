
module bindgen::impl::wter @private;
import bindgen::bg, bindgen::impl @public;
import std::io, clang;

const INDENT @local = "  ";

<*
 Writes aliasing typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz? typedefAlias(
  File* out,
  WriteState* state,
  String name,
  String underlying_name,
  WriteAttrs attribs = {})
@maydiscard
{
  state.kind = ALIAS;

  usz? acc;
  acc += io::fprintfn(out, "\nalias %s%s = %s;", name, attribs, underlying_name);
  return acc;
}

<*
 Writes distinct typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz? typedefDist(
  File* out,
  WriteState* state,
  String name,
  String underlying_name,
  WriteAttrs attribs = {}) 
@maydiscard
{
  state.kind = TYPEDEF;

  usz? acc;
  acc += io::fprintfn(out, "\ntypedef %s%s = %s;", name, attribs, underlying_name);
  return acc;
}

<*
 Writes function pointer typedef to 'out'
 @returns "Number of bytes written"
*>
fn usz? typedefFunc(
  File* out,
  WriteState* state,
  String name,
  String return_type,
  VarDecl[] params,
  WriteAttrs attribs = {})
@maydiscard
{
  state.kind = ALIAS;

  usz? acc;
  
  acc += io::fprintf(out, "\nalias %s%s = fn %s(", name, attribs, return_type);
  
  if (params.len > 0) acc += io::fprintf(out, "\n");

  foreach (i, p : params) {
    acc += io::fprintf(out, "  %s", p.type);
    if (p.name) {
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
  WriteState* state,
  String type,
  String name,
  String value,
  WriteAttrs attribs = {},
  bool new_line = true)
@maydiscard
{
  WriteKind prev_kind = state.kind;
  state.kind = CONST;

  usz? acc;

  if (prev_kind != CONST && prev_kind != ENUM) acc += io::fprintf(out, "\n");

  if (type == "") {
    acc += io::fprintfn(out, "const %s%s = %s;", name, attribs, value);
  } else {
    acc += io::fprintfn(out, "const %s %s%s = %s;", type, name, attribs, value);
  }

  return acc;
}

<*
 Writes global variable to 'out'
 @returns "Number of bytes written"
*>
fn usz? varDecl(
  File* out,
  WriteState* state,
  String type,
  String name,
  String value,
  WriteAttrs attribs = {})
@maydiscard
{
  state.kind = VAR;

  usz? acc;

  if (value == "") {
    acc += io::fprintfn(out, "\n%s %s%s;", type, name, attribs);
  } else {
    acc += io::fprintfn(out, "\n%s %s%s = %s;", type, name, attribs, value);
  }

  return acc;
}

<*
 Writes type declaration enum to 'out'
 @returns "Number of bytes written"
*>
fn usz? enumDecl(
  File* out,
  WriteState* state,
  String name,
  String type,
  WriteAttrs attribs = {})
@maydiscard
{
  state.kind = ENUM;

  return io::fprintfn(out, "\ntypedef %s%s = inline %s;", name, attribs, type);
}

<*
 Writes function to 'out'
 @returns "Number of bytes written"
*>
fn usz? func(
  File* out,
  WriteState* state,
  VarDecl[] params,
  String return_type,
  String original_name,
  String name,
  WriteAttrs attribs = {}) 
@maydiscard
{
  state.kind = FUNC;

  usz? acc;

  acc += io::fprintf(out, "\nfn %s %s(", return_type, name);
  if (params.len > 0) acc += io::fprintf(out, "\n");

  foreach (i, p : params)  {
    acc += io::fprintf(out, "  %s", p.type);
    if (p.name) {
      acc += io::fprintf(out, " %s", p.name);
    }
    if (i < params.len - 1) acc += io::fprintn(out, ", ");
  }
  acc += io::fprintfn(out, ")\n@extern(\"%s\")%s;", original_name, attribs);

  return acc;
}

<*
 Writes function to 'out'
 @return "Number of bytes written"
*>
fn usz? funcMacro(
  File* out,
  WriteState* state,
  String[] params,
  String name,
  String body,
  WriteAttrs attribs = {})
@maydiscard
{
  state.kind = MACRO;

  usz? acc;

  acc += io::fprintf(out, "\nmacro @%s(", name);
  foreach (i, p : params) {
    acc += io::fprintf(out, "#%s", p);
    if (i < params.len - 1) acc += io::fprint(out, ", ");
  }
  acc += io::fprintf(out, ")%s {", attribs);
  
  if (body != "") {
    acc += io::fprintfn(out, "\n%s%s", INDENT, body);
  }

  acc += io::fprintfn(out, "}");

  return acc;
}

<*
 Writes module name to 'out'
 @returns "Number of bytes written"
*>
fn usz? moduleHead(
  File* out,
  WriteState* state,
  String module_name,
  WriteAttrs attribs = {})
@maydiscard
{
  state.kind = MODULE;

  return io::fprintfn(out, "\nmodule %s%s;", module_name, attribs);
}

fn usz? importModule(
  File* out,
  WriteState* state,
  String module_name)
@maydiscard
{
  state.kind = IMPORT;

  return io::fprintfn(out, "import %s;", module_name);
}


fn usz? structDecl(
  File* out,
  WriteState* state,
  String name,
  C3Fields* fields,
  usz indent_level = 0,
  WriteAttrs attribs = {}) 
@maydiscard
{
  state.kind = STRUCT;

  usz? acc;

  acc += printIndent(out, indent_level);
  
  if (indent_level == 0) acc += io::fprintf(out, "\n");

  if (name == "")
  {
    acc += io::fprintfn(out, "struct {");
  }
  else
  {
    acc += io::fprintfn(out, "struct %s%s {", name, attribs);
  }

  acc += wter::fields(out, state, fields, indent_level + 1);

  acc += printIndent(out, indent_level);
  acc += io::fprintfn(out, "}");
  
  return acc;
}


fn usz? unionDecl(
  File* out,
  WriteState* state,
  String name,
  C3Fields* fields,
  usz indent_level = 0,
  WriteAttrs attribs = {}) 
@maydiscard
{
  state.kind = UNION;

  usz? acc;

  acc += printIndent(out, indent_level);

  if (indent_level == 0) acc += io::fprintf(out, "\n");

  if (name == "")
  {
    acc += io::fprintfn(out, "union {");
  }
  else
  {
    acc += io::fprintfn(out, "union %s%s {", name, attribs);
  }

  acc += wter::fields(out, state, fields, indent_level + 1);

  acc += printIndent(out, indent_level);
  acc += io::fprintfn(out, "}");
  
  return acc;
}


fn usz? fields(
  File* out,
  WriteState* state,
  C3Fields* fields,
  usz indent_level)
{
  usz? acc;

  fields.@foreach(; C3FieldKind* kind, usz index)
  {
    switch (*kind)
    {
      case NORMAL:
        acc += printIndent(out, indent_level);
        acc += io::fprintfn(out, "%s %s;", fields.norm[index].type, fields.norm[index].name);

      case BITSTRUCT:
        state.kind = BITSTRUCT;

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
        acc += wter::structDecl(out, state, fields.structs[index].name, &fields.structs[index].fields, indent_level);

      case UNION:
        acc += wter::unionDecl(out, state, fields.unions[index].name, &fields.unions[index].fields, indent_level);
        
      default: unreachable();
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

fn usz? printLines(
  File* out,
  usz lines_number = 1)
{
  usz? acc;
  for (usz i; i < lines_number; ++i) acc += io::fprintf(out, "\n");
  return acc;
}

