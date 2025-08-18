
module bgimpl::check;
import bindgen::bg;

<*
 Applies fun to s, returning false
 if fun is null.
*>
fn bool apply(
  String s, 
  BGCheckFn fun) 
  @inline
{
  if (fun == null) return false;
  return fun(s);
}

