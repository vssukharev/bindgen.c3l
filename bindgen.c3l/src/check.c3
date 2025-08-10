
module bgimpl::check;
import bindgen::bg;

fn bool apply(
  String s, 
  BGCheckFn fun) 
@inline
{
  if (fun == null) return false;
  return fun(s);
}

