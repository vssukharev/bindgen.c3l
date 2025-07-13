
module bindgen::impl::valgen @private;
import bindgen::bg, bindgen::impl @public;

<*
 Applies fun to a name for value generation and returns a corresponding result
 @require @typeis(fun, BGGenFn) ||| @typeis(fun, BGModuleWrapFn)
*>
macro apply(
  Allocator alloc, 
  String name,  
  fun)
{
  var $RetType = $typefrom($typeof(fun).returns);
  if (fun == null) return ($RetType){};

  $RetType res = fun(name, alloc);
  return res;
}

<*
 Gets write attributes for the name and allocates them via allocator
*>
fn WriteAttrs getWriteAttrs(
  Allocator alloc, 
  String name, 
  BGGenCallbacks gen_fns)
{
  WriteAttrs res;
  res.init(alloc);
  String if_arg = (String) valgen::apply(alloc, name, gen_fns.if_condition);
  if (if_arg != "") res.push(IF, if_arg);
  return res;
}

<*
 Writes a new module section for the name
 if needed based on gen_fns.module_wrap. 
 Note: if two names in a row got the same module name,
 new section is not written.
*>
fn void moduleWrap(
  GlobalVisitData* vd, 
  String name) 
=> @pool()
{
  BGModuleWrap curr = valgen::apply(tmem, name, vd.gen_fns.module_wrap);

  if (!curr.equals(&vd.prev_module_wrap)) {
    vd.prev_module_wrap = curr;

    WriteAttrs attrs;
    attrs.init(tmem);
    if (curr.if_condition != "") attrs.push(IF, curr.if_condition);

    wter::moduleHead(vd.out, &vd.write_state, vd.module_name, attrs);

    if (curr.imports != "") {
      String[] imports_arr = curr.imports.tsplit(";", skip_empty: true);
      foreach (imp : imports_arr) {
        wter::importModule(vd.out, &vd.write_state, imp.trim_left());
      }
    }
  }
}

