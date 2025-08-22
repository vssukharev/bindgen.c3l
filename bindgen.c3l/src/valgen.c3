
module bgimpl::valgen;
import bindgen::bg, 
       bgimpl;


<*
 Applies fun to a name for value generation.
 If function is null, returns the default value
 of return type.
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
 Gets write attributes for the name and allocates them via allocator.
 Uses the following callbacks of gen_fns to generate values for attributes:
 1. if_condition - if not empty, stand for '@if' value
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
 Writes a new module section for the name if needed
 to vd.out, based on vd.gen_fns.module_wrap (see BGModuleWrap docs).
 If two names in a row returned the same module wrap, new 
 section is not written.
 Module section inherents name from vd.module_name.
 @param [&inout] vd
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

