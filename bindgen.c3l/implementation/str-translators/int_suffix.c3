
module bindgen::bg @private;

<*
 The only translation is substituting 'LL' or 'll' to 'L' and 'l' respectively.
 Technically, suffix can be mixed, e.g. 'LLu', 'ull', 'llU' - only 'll'
 and 'LL' must be together and in the same case.
*>
fn String String.newTransIntSuffix(String literal, Allocator alloc = allocator::heap())
{
  if (literal.len == 0 || literal[0] == '"') return literal.copy(alloc);

  usz! loc = literal.index_of("LL") ?? literal.index_of("ll");
  if (catch loc) return literal.copy(alloc); // It doesn't contain LL or ll

  String new = (String) allocator::alloc_array(alloc, char, literal.len-1);

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

fn String String.tempTransIntSuffix(String literal) =>
  literal.newTransIntSuffix(allocator::temp()) @inline;


