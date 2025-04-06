
module bindgen::impl @private;
import bindgen::bg;
import std::io, std::collections::map, std::collections::list, clang;

// --- Helper Structures

<*
 Translation table maps C name to C3 name. 
 For instance: { .key = "int", .val = "CInt" } is "int" -> "CInt".
*>
alias TransTable = HashMap{String, String};
alias VarDeclList = List{VarDecl};
alias EnumMemberList = List{EnumMember};

struct VarDecl
{
  String type;
  String name;
}

struct EnumMember
{
  String name;
  String val;
}

<*
 BIT : "Means bit field if used in CFields; means bitstruct when used in C3Fields"
*>
enum FieldKind : char
{
  NORMAL, 
  STRUCT,
  UNION,
  BIT,
}

struct CFieldBit
{
  String  type;
  String  name;
  usz     width;
}

<*
 name : "Optional, can be zero string"
*>
struct CFieldAnon
{
  String  name;
  CFields fields;
}

<* 
  kinds.len == sum of *.len 
*>
struct CFields
{
  List{FieldKind}   kinds;
  List{VarDecl}     norm;
  List{CFieldBit}   bit;
  List{CFieldAnon}  structs;
  List{CFieldAnon}  unions;
}

macro void CFields.init(&self, Allocator alloc)
{
  $foreach $member : CFields.membersof:
    self.$eval($member.nameof).init(alloc);
  $endforeach
}

<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro CFields.@foreach(&self; @body(FieldKind* kind, usz index))
{
  usz[FieldKind.elements] counters;

  foreach (i, &k : self.kinds)
  {
    @body(k, counters[k.ordinal]);
    ++counters[k.ordinal];
  }
}

<*
 name : "Optional, can be zero string"
*>
struct C3FieldAnon
{
  String    name;
  C3Fields  fields;
}

struct BitstructMember
{
  String  type;
  String  name;
  usz     from;
  usz     to;
}

<*
 under_type : "Underlying type of a bitstruct (bitstruct : under_type { ... })"
*>
struct C3FieldBitstruct
{
  String                under_type;
  List{BitstructMember} fields;
}

<* 
  kinds.len == sum of *.len 
*>
struct C3Fields
{
  List{FieldKind}         kinds;
  List{VarDecl}           norm;
  List{C3FieldBitstruct}  bit;
  List{C3FieldAnon}       structs;
  List{C3FieldAnon}       unions;
}

macro void C3Fields.init(&self, Allocator alloc)
{
  $foreach $member : C3Fields.membersof:
    self.$eval($member.nameof).init(alloc);
  $endforeach
}

<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro C3Fields.@foreach(&self; @body(FieldKind* kind, usz index))
{
  usz[FieldKind.elements] counters;

  foreach (i, &k : self.kinds)
  {
    @body(k, counters[k.ordinal]);
    ++counters[k.ordinal];
  }
}


// --- Visit Data

struct GlobalVisitData
{
  BGTransCallbacks  trans_fns;
  BGGenCallbacks    gen_fns;
  TransTable        types_table;
  BGCheckFn         include_file;
  File*             out;
  CXFile            cxfile; // used to ignore nodes from other files 
  usz               anon_fns_counter;
  bitstruct : char
  {
    bool            no_verbose;
  }
}

<*
 allocator : "All string are allocated via it"
*>
struct FuncVisitData
{
  VarDeclList       params;
  Allocator         allocator;
  GlobalVisitData*  g;
}

<*
 allocator : "All string are allocated via it"
*>
struct FieldsVisitData
{
  CXCursor          prev_anon;
  CFields           fields;
  Allocator         allocator;
  GlobalVisitData*  g;
  usz               current;
}

struct TypedefVisitData
{
  GlobalVisitData* g;
}

<*
 allocator : "val is allocated via it"
*>
struct ConstVisitData
{
  String            val;
  Allocator         allocator;
  GlobalVisitData*  g;
}

<*
 allocator : "All string are allocated via it"
*>
struct EnumVisitData
{
  EnumMemberList    members;
  Allocator         allocator;
  GlobalVisitData*  g;
  bool              is_unsigned;
}

// --- Writers Data

enum WriteAttrKind : char (inline String str, bool has_arg)
{
  PRIVATE = { "@private", false },
  IF      = { "@if"     , true  },
}

<*
 Only kind with kind.has_arg == true can have an arg
*>
struct WriteAttrs (Printable)
{
  List{WriteAttrKind} kinds;
  List{String}        args;
}

macro WriteAttrs* WriteAttrs.init(&self, Allocator alloc)
{
  self.kinds.init(alloc, 2);
  self.args.init(alloc, 1);
  return self;
}

macro void WriteAttrs.push(&self, WriteAttrKind $kind, String val = "")
{
  self.kinds.push($kind);
  $switch $kind:
    $case IF:
      self.args.push(val);
  $endswitch
}

fn usz? WriteAttrs.to_format(&self, Formatter* form) @dynamic
{
  usz? acc;

  usz i;
  foreach (k : self.kinds)
  {
    if (k.has_arg)
    {
      acc += form.printf(" %s(%s)", k.str, self.args[i]);
      ++i;
    }
    else
    {
      acc += form.printf(" %s", k.str);
    }
  }
  return acc;
}


