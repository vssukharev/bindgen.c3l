
module bindgen::impl::valgen @private;
import bindgen::bg, bindgen::impl @public;

<*
 @require $typeof(fun).typeid == BGGenFn.typeid || $typeof(fun).typeid == BGModuleWrapFn.typeid
*>
macro apply(Allocator alloc, String s, fun)
{
  var $RetType = $typefrom($typeof(fun).returns);
  if (fun == null) return ($RetType){};

  $RetType res = fun(s, alloc);
  return res;
}

fn WriteAttrs getWriteAttrs(Allocator alloc, String name, BGGenCallbacks gen_fns)
{
  WriteAttrs res;
  res.init(alloc);
  String if_arg = (String) valgen::apply(alloc, name, gen_fns.if_condition);
  if (if_arg != "") res.push(IF, if_arg);
  return res;
}

fn void moduleWrap(GlobalVisitData* vd, String name) => @pool()
{
  BGModuleWrap curr = valgen::apply(tmem, name, vd.gen_fns.module_wrap);

  if (!curr.equals(&vd.prev_module_wrap))
  {
    vd.prev_module_wrap = curr;

    WriteAttrs attrs;
    attrs.init(tmem);
    if (curr.if_condition != "") attrs.push(IF, curr.if_condition);

    wter::moduleHead(vd.out, vd.module_name, attrs);

    if (curr.imports != "")
    {
      String[] imports_arr = curr.imports.tsplit(";", skip_empty: true);
      foreach (imp : imports_arr)
      {
        wter::importModule(vd.out, imp.trim_left());
      }
    }
  }
}

