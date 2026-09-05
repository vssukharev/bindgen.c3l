<*
 Section provides necessary methods
 for structures defined in data.c3
*>
module bgimpl::data_methods;
import bindgen::bg,
       std::io,
       clang;


fn bool BGModuleWrap.equals(
  &self, 
  BGModuleWrap* other)
  @operator(==)
{
  return self.if_condition == other.if_condition;
}

<*
 Initializes each member of CFields via .init(alloc) method
*>
macro void CFields.init(
  &self, 
  Allocator alloc)
{
  $foreach $member : CFields::members:
    self.$eval($member.name).init(alloc);
  $endforeach
}


<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro CFields.@foreach(
  &self; 
  @body(CFieldKind* kind, sz index))
{
  sz[CFieldKind::values.len] counters;

  foreach (i, &k : self.kinds) {
    @body(k, counters[k.ordinal]);
    ++counters[k.ordinal];
  }
}


<*
 Initializes each member of C3Fields via .init(alloc) method
*>
macro void C3Fields.init(
  &self, 
  Allocator alloc)
{
  $foreach $member : C3Fields::members:
    self.$eval($member.name).init(alloc);
  $endforeach
}


<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro C3Fields.@foreach(
  &self; 
  @body(C3FieldKind* kind, sz index))
{
  sz[C3FieldKind::values.len] counters;

  foreach (i, &k : self.kinds)
  {
    @body(k, counters[k.ordinal]);
    ++counters[k.ordinal];
  }
}


<*
 Initializes all Lists in CTypeTokens
*>
macro void CTypeTokens.init(
  &self, 
  Allocator alloc)
{
  self.kinds.init(alloc);
  self.strs.init(alloc);
}


<*
 Frees all Lists in CTypeTokens
*>
macro void CTypeTokens.free(&self)
{
  self.kinds.free();
  self.strs.free();
}


<*
 Iterates through CTypeTokens in reversed order,
 returning the kind and index of a name string.
 If token is represented with const string,
 sets index to usz.max.
*>
macro CTypeTokens.@foreach(
  &self; 
  @body(CTypeTokenKind kind, sz str_index))
{
  sz str_counter;
  sz str_len = self.strs.len();
  foreach_r (k : self.kinds) {
    sz str_index = sz::max;
    switch (k) {
      case NAME:
      case SIZED_ARRAY:
        str_index = str_len - ++str_counter;
      default:
    }

    @body(k, str_index);
  }
}



<*
 @require $kind != NAME || val != ""        : `val must be set to "<name>" in case of $kind == NAME`
 @require $kind != SIZED_ARRAY || val != "" : `val must be set to "[<array_size>]" in case of $kind == SIZED_ARRAY`
*>
macro void CTypeTokens.push(
  &self, 
  CTypeTokenKind $kind, 
  String val = "")
{
  self.kinds.push($kind);

  $switch $kind:
    $case NAME:
    $case SIZED_ARRAY:
      self.strs.push(val);
    $default:
  $endswitch
}


<*
 Formats the WriteAttrs as such they should be 
 printed within C3 declaration.
 Iterates through fields of WriteAttrs and if
 a field has type bool, it is considered as
 attribute without argument. Otherwise, the
 field is formatted as a parameterized attribute.
 Information about how the specific attribute is printed,
 must be contained in str @tag of the field.
*>
fn sz? WriteAttrs.to_format(
  &self, 
  Formatter* format) 
  @dynamic
{
  sz? acc;

  $foreach $f : WriteAttrs::members:
    assert( $f.has_tag("attr") );
    String $attr = $f.get_tag("attr");

    $switch $f.type.kind:
      $case String::kind:
        if ($f.get(*self) != "") {
          acc += format.printf(" %s(%s)", $attr, $f.get(*self));
        }
      $case bool::kind:
        if ($f.get(*self)) {
          acc += format.printf(" %s", $attr);
        }
      $default:
        $error "Unexpected type in WriteAttrs fields";
    $endswitch
  $endforeach

  return acc;
}


fn uint CXType.hash(
  CXType t) 
{
  return clang::hashCursor(clang::getTypeDeclaration(t)) @inline;
}


fn bool CXType.equals(
  CXType a, 
  CXType b) 
  @operator(==)
{
  return (bool)clang::equalTypes(a, b) @inline;
}


module std::core::array;


<*
 Returns true if predicate returns true at least one time. Returns false otherwise.
 @require $Typeof(arr)::kind == SLICE ||| $kindof(arr) == ARRAY       : "Array must be either slice or array"
 @require $Typeof(predicate)::kind == FUNC                              : "Predicate must be a function"
 @require $Typeof(predicate)::returns == bool                 : "Predicate must return bool"
 @require $Typeof(predicate)::params.len == 1                      : "Predicate must have one parameter"
 @require $Typeof(predicate)::params[0].type == $Typeof(arr)::inner : "Predicate must have parameter of inner array type"
*>
macro has(arr, predicate)
{
  foreach (e : arr) if (predicate(e)) return true;
  return false;
}



