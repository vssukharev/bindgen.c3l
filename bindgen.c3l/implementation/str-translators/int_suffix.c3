
module bindgen::bg @private;
import std::ascii;

<*
 The only translation is substituting 'LL' or 'll' to 'L' and 'l' respectively.
 Technically, suffix can be mixed, e.g. 'LLu', 'ull', 'llU' - only 'll'
 and 'LL' must be together and in the same case.
*>
fn String strTransIntSuffix(
  String literal)
{
  if (literal[0] == '"') return literal.copy(); // TODO: CORRECTLY HANDLE STIRNG LITERALS

  usz! loc = literal.index_of("LL") ?? literal.index_of("ll");
  if (catch loc) return literal.copy(); // return copy here
  
  log("%s", literal, indent: 1);

  String new = (String) mem::alloc_array(char, literal.len-1);

  // copy left side
  mem::copy(new.ptr, literal.ptr, loc + 1);

  // copy right side
  if (new.len - loc - 1 > 0) 
  {
    mem::copy(
      new.ptr + (loc + 1), 
      literal.ptr + (loc + 2), 
      new.len - loc - 1
    );
  }

  return new;
}


