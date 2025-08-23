<*
 The module contains writer functions.
 Each such function changes WriteState,
 writes it's formatted parameters to
 out without extra logic and returns
 the number of bytes written.
*>
module bgimpl::wter;
import bindgen::bg, 
       bgimpl, 
       std::io, 
       clang;


const INDENT = "  ";


<*
 Aliasing typedef
*>
fn usz? typedefAlias(
  OutStream out,
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
 Distinct typedef
*>
fn usz? typedefDist(
  OutStream out,
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
 Function pointer typedef
*>
fn usz? typedefFunc(
  OutStream out,
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
 Constant declaration
*>
fn usz? constDecl(
  OutStream out,
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
 Global variable declaration
*>
fn usz? varDecl(
  OutStream out,
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
 Enum declaration without it's underlying constants
*>
fn usz? enumDecl(
  OutStream out,
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
 Function declaration
*>
fn usz? func(
  OutStream out,
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
 Functional macro
*>
fn usz? funcMacro(
  OutStream out,
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
 Module section statement
 @param [&out] state                : "Sets state.kind to WriteKind.MODULE"
 @require module_name != ""         : "Module name can't be empty"
 @require module_name[0].is_lower() : "Module name must start with lower case letter"
*>
fn usz? moduleHead(
  OutStream out,
  WriteState* state,
  String module_name,
  WriteAttrs attribs = {})
  @maydiscard
{
  state.kind = MODULE;

  return io::fprintfn(out, "\nmodule %s%s;", module_name, attribs);
}


<*
 Import statemenet 
*>
fn usz? importModule(
  OutStream out,
  WriteState* state,
  String to_import)
  @maydiscard
{
  state.kind = IMPORT;

  return io::fprintfn(out, "import %s;", to_import);
}


<*
 Struct declaration
*>
fn usz? structDecl(
  OutStream out,
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

  if (name == "") {
    acc += io::fprintfn(out, "struct {");
  } else {
    acc += io::fprintfn(out, "struct %s%s {", name, attribs);
  }

  acc += wter::fields(out, state, fields, indent_level + 1);

  acc += printIndent(out, indent_level);
  acc += io::fprintfn(out, "}");
  
  return acc;
}


<*
 Union declaration
*>
fn usz? unionDecl(
  OutStream out,
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


<*
 Helper function for wter::structDecl and wter::unionDecl,
 which writes record fields
*>
fn usz? fields(
  OutStream out,
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

        foreach (C3BitstructField bitf : fields.bit[index].fields)
        {
          acc += printIndent(out, indent_level + 1);
          acc += io::fprintfn(out, "%s %s : %s..%s;", bitf.type, bitf.name, bitf.from, bitf.to)!;
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


<*
 Helper printer
*>
fn usz? printIndent( 
  OutStream out, 
  usz indent_level = 1)
{
  usz? acc;
  for (usz i; i < indent_level; ++i) acc += io::fprintf(out, INDENT);
  return acc;
}


<*
 Helper printer
*>
fn usz? printLines(
  OutStream out,
  usz lines_number = 1)
{
  usz? acc;
  for (usz i; i < lines_number; ++i) acc += io::fprintf(out, "\n");
  return acc;
}

