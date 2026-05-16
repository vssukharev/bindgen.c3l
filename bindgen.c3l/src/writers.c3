<*
 The module contains writer functions.
 Each such function changes WriteState,
 writes it's formatted parameters to
 out without extra logic or checks and returns
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
 @param [&inout] out
 @param [&out]   state  : "Sets state.kind to WriteKind.ALIAS"
 @require name            != ""
 @require underlying_name != ""
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
 @param [&inout] out
 @param [&out]   state  : "Sets state.kind to WriteKind.TYPEDEF"
 @require name            != ""
 @require underlying_name != ""
*>
fn usz? typedefDistinct(
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
 @param [&inout] out
 @param [&out]   state                                                            : "Sets state.kind to WriteKind.ALIAS"
 @require !array::has(params, fn bool(VarDecl e) => e.type == "" && e.name != "") : "Each parameter must have type if it has name"
 @require name        != ""
 @require return_type != ""
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
    acc += io::fprintf(out, INDENT+++"%s", p.type);
    if (p.name) {
      acc += io::fprintf(out, " %s", p.name);
    }
    if (i < params.len - 1) acc += io::fprintn(out, ",");
  }

  acc += io::fprintn(out, ");");
  
  return acc;
}


<*
 Constant declaration.
 If state.kind is CONST or ENUM, does not write extra 
 new line at the beginning.
 @param [&inout] out
 @param [&inout] state : "Sets state.kind to CONST"
 @param          type  : "Can be empty, for example, for macro"
 @require name  != ""
 @require value != ""
*>
fn usz? constDecl(
  OutStream out,
  WriteState* state,
  String type,
  String name,
  String value,
  WriteAttrs attribs = {})
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
 @param [&inout] out
 @param [&inout] state : "Sets state.kind to CONST"
 @param          value : "Can be empty"
 @require type != ""
 @require name != ""
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
 @param [&inout] out
 @param [&inout] state : "Sets state.kind to ENUM"
 @require name != ""
 @require type != ""
*>
fn usz? enumDecl(
  OutStream out,
  WriteState* state,
  EnumField[] fields,
  String name,
  String type,
  WriteAttrs attribs = {})
  @maydiscard
{
	state.kind = ENUM;

	usz? acc;

	acc += io::fprintfn(out, "\nconstdef %s%s : %s {", name, attribs, type);

	foreach (i, p : fields)  {
		acc += io::fprintf(out, INDENT+++"%s =", p.name);
		acc += io::fprintf(out, " %s", p.init);
		if (i < fields.len - 1) acc += io::fprintn(out, ",");
  	}

	acc += io::fprintfn(out, "\n}");

	return acc;
}


<*
 Function declaration
 @param [&inout] out
 @param [&inout] state                                                            : "Sets state.kind to FUNC"
 @require !array::has(params, fn bool(VarDecl e) => e.type == "" && e.name != "") : "Each parameter must have type if it has name"
 @require return_type   != ""
 @require original_name != ""
 @require name          != ""
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

  acc += io::fprintf(out, "\nextern fn %s %s(", return_type, name);
  if (params.len > 0) acc += io::fprintf(out, "\n");

  foreach (i, p : params)  {
    acc += io::fprintf(out, INDENT+++"%s", p.type);
    if (p.name) {
      acc += io::fprintf(out, " %s", p.name);
    }
    if (i < params.len - 1) acc += io::fprintn(out, ",");
  }
  acc += io::fprintfn(out, ")\n@cname(\"%s\")%s;", original_name, attribs);

  return acc;
}


<*
 Functional macro
 @param [&inout] out
 @param [&inout] state                                          : "Sets state.kind to MACRO"
 @param          body                                           : "Can be empty"
 @require !array::has(params, fn bool(String val) => val == "") : "params can't contain empty entries"
 @require name != ""
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
    acc += io::fprintfn(out, "\n"+++INDENT+++"%s", body);
  }

  acc += io::fprintfn(out, "}");

  return acc;
}


<*
 Module section statement
 @param [&inout] out
 @param [&out]   state : "Sets state.kind to WriteKind.MODULE"
 @require module_name != ""
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
 @param [&inout] out
 @param [&out]   state : "Sets state.kind to WriteKind.IMPORT"
 @require import_module != ""
*>
fn usz? importModule(
  OutStream out,
  WriteState* state,
  String import_module)
  @maydiscard
{
  state.kind = IMPORT;

  return io::fprintfn(out, "import %s;", import_module);
}


<*
 Struct declaration
 @param [&inout] out
 @param [&in]    fields
 @param [&out]   state  : "Sets state.kind to WriteKind.IMPORT"
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

  if (name == "") {
    acc += io::fprintfn(out, "union {");
  } else {
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

