
module bindgen::impl::valgen @private;
import bindgen::bg, bindgen::impl @public;

fn String apply(Allocator alloc, String s, BGGenFn fun) @inline
{
  if (fun == null) return "";
  String res = fun(s, alloc);
  return res;
}

fn WriteAttrs getWriteAttrs(Allocator alloc, String name, BGGenCallbacks gen_fns)
{
  WriteAttrs res;
  res.init(alloc);

  String if_arg = valgen::apply(tmem, name, gen_fns.if_condition);
  if (if_arg == "")
  {
    return res;
  }
  
  res.push(IF, if_arg);
  return res;
}

