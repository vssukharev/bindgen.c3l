
module bindgen::bg @private;
import std::io, clang;

<*
 TODO: turn 'vals_name' and 'vals_rhs' to pointers and pass length as separate parameter

 Writes enum with values to 'out'

 @returns "Number of bytes written"
*>
fn usz! writeEnum(
  File* out,
  String name,
  String type,
  EnumVals vals)
@maydiscard
{
  usz acc;
  
  acc += io::fprintfn(out, "\ndistinct %s = inline %s;", name, type)!;
  for (usz i; i < vals.len; ++i)
  {
    acc += io::fprintfn(out, "const %s %s = %s;", name, vals.names[i], vals.rhses[i])!;
  }
  
  return acc;
}

