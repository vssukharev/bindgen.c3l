<*
 Section provides necessary methods
 for structures defined in data.c3
*>
module bgimpl;
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
  $foreach $member : CFields.membersof:
    self.$eval($member.nameof).init(alloc);
  $endforeach
}


<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro CFields.@foreach(
  &self; 
  @body(CFieldKind* kind, usz index))
{
  usz[CFieldKind.values.len] counters;

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
  $foreach $member : C3Fields.membersof:
    self.$eval($member.nameof).init(alloc);
  $endforeach
}


<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro C3Fields.@foreach(
  &self; 
  @body(C3FieldKind* kind, usz index))
{
  usz[C3FieldKind.values.len] counters;

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
  @body(CTypeTokenKind kind, usz str_index))
{
  usz str_counter;
  usz str_len = self.strs.len();
  foreach_r (k : self.kinds) {
    usz str_index = usz.max;
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
fn usz? WriteAttrs.to_format(
  &self, 
  Formatter* form) 
  @dynamic
{
  usz? acc;

  $foreach $f : WriteAttrs.membersof:
    assert( WriteAttrs.$eval($f.nameof).has_tagof("attr") );
    String $attr = WriteAttrs.$eval($f.nameof).tagof("attr");

    $switch $f.typeid:
      $case String:
        if (self.$eval($f.nameof) != "") {
          acc += form.printf(" %s(%s)", $attr, self.$eval($f.nameof));
        }
      $case bool:
        if (self.$eval($f.nameof)) {
          acc += form.printf(" %s", $attr);
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

