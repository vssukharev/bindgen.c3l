
module bindgen::bg @private;
import std::io, clang;

<*
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
  
  acc += io::fprintfn(out, "distinct %s = inline %s;", name, type)!;
  for (usz i; i < vals.len; ++i)
  {
    acc += io::fprintfn(out, "const %s %s = %s;", name, vals.names[i], vals.rhses[i])!;
  }
  acc += io::fprintn(out)!;
  
  return acc;
}

