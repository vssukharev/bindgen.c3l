
module bindgen::impl::check @private;
import bindgen::bg, bindgen::impl @public;

fn bool apply(String s, BGCheckFn fun) @inline
{
  if (fun == null) return false;
  return fun(s);
}

