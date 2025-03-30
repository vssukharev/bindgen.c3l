
module bindgen::impl::valgen @private;
import bindgen::bg, bindgen::impl @public;

fn String apply(Allocator alloc, String s, BGGenFn fun) @inline
{
  if (fun == null) return "";
  String res = fun(s, alloc);
  return res;
}

