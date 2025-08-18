<*
 Section provides necessary methods
 for structures defined in data.c3
*>
module bgimpl;
import bindgen::bg,
       std::io;


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
 @require $kind != NAME || val != "" : `val must be set to "<name>" in case of $kind == NAME`
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
 Initializes WriteAttrs Lists
*>
macro WriteAttrs* WriteAttrs.init(
  &self, 
  Allocator alloc)
{
  self.kinds.init(alloc, 2);
  self.args.init(alloc, 1);
  return self;
}


<*
 @require $kind != IF || val != "" : "val must be set to @if condition in case of $kind == IF"
*>
macro void WriteAttrs.push(
  &self, 
  WriteAttrKind $kind, 
  String val = "")
{
  self.kinds.push($kind);
  $switch $kind:
    $case IF:
      self.args.push(val);
  $endswitch
}


<*
 Formats the WriteAttrs as such they should be 
 printed within C3 declaration
*>
fn usz? WriteAttrs.to_format(
  &self, 
  Formatter* form) 
  @dynamic
{
  usz? acc;
  usz i;
  foreach (k : self.kinds) {
    if (k.has_arg) {
      acc += form.printf(" %s(%s)", k.str, self.args[i]);
      ++i;
    } else {
      acc += form.printf(" %s", k.str);
    }
  }
  return acc;
}


<*
 Those functions are defines for HashMap to work with CXType as key
*>
module clang;


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

