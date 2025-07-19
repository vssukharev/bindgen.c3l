
module clang;

macro uint CXType.hash(&self) => clang::hashCursor(clang::getTypeDeclaration(*self));
macro bool CXType.equals(CXType a, CXType b) @operator(==) => (bool) clang::equalTypes(a, b);

module bindgen::impl @private;
import bindgen::bg;
import std::io, std::collections::map, std::collections::list, clang;

// --- Types table

<*
 Types translation table maps CXType to C3 name. 
*>
alias TypesTable = HashMap{CXType, String};


// --- Helper Structures

alias VarDeclList = List{VarDecl};

struct VarDecl
{
  String type;
  String name;
}

enum CFieldKind : char
{
  NORMAL,
  STRUCT,
  UNION,
  BIT,
  ENUM,
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
  List{CFieldKind}   kinds;
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
macro CFields.@foreach(&self; @body(CFieldKind* kind, usz index))
{
  usz[CFieldKind.values.len] counters;

  foreach (i, &k : self.kinds)
  {
    @body(k, counters[k.ordinal]);
    ++counters[k.ordinal];
  }
}

enum C3FieldKind : char
{
  NORMAL,
  BITSTRUCT,
  STRUCT,
  UNION
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
  List{C3FieldKind}       kinds;
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
macro C3Fields.@foreach(&self; @body(C3FieldKind* kind, usz index))
{
  usz[C3FieldKind.values.len] counters;

  foreach (i, &k : self.kinds)
  {
    @body(k, counters[k.ordinal]);
    ++counters[k.ordinal];
  }
}

enum TypeTokenKind : char
{
  NAME,           // 'struct' or 'MyType'
  POINTER,        // *
  SIZED_ARRAY,    // [10]
  UNSIZED_ARRAY,  // []
}

struct TypeTokens
{
  List{TypeTokenKind} kinds;
  List{String}        strs; // everything that is unknown at compile-time
}

macro void TypeTokens.init(&self, Allocator alloc)
{
  self.kinds.init(alloc);
  self.strs.init(alloc);
}

macro void TypeTokens.free(&self)
{
  self.kinds.free();
  self.strs.free();
}

<*
 Iterates through kinds and returns corresponding 
 index for fields depending on the kind
*>
macro TypeTokens.@foreach(&self; @body(TypeTokenKind kind, String str))
{
  usz str_counter;
  usz str_len = self.strs.len();
  foreach_r (k : self.kinds) {
    String str;
    switch (k) {
      case NAME:
      case SIZED_ARRAY:
        str = self.strs[str_len - ++str_counter];
      case UNSIZED_ARRAY:
      case POINTER:
        str = "*";
    }

    @body(k, str);
  }
}

macro void TypeTokens.push(&self, TypeTokenKind $kind, String val = "")
{
  self.kinds.push($kind);

  $switch $kind:
    $case NAME:
    $case SIZED_ARRAY:
      self.strs.push(val);
    $default:
  $endswitch
}

enum WriteKind
{
  ALIAS, TYPEDEF,
  FUNC, CONST, 
  UNION, ENUM,
  MACRO, MODULE,
  IMPORT, STRUCT,
  VAR, BITSTRUCT,
}

struct WriteState
{
  WriteKind kind;
}

// --- Visit Data

struct GlobalVisitData
{
  BGTransCallbacks  trans_fns;
  BGGenCallbacks    gen_fns;
  BGCheckFn         include_file;
  String            module_name;
  BGModuleWrap      prev_module_wrap;

  TypesTable        types_table;
  File*             out;
  CXFile            cxfile; // used to ignore nodes from other files 
  usz               anon_fns_counter;
  WriteState        write_state;

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
 prev_inline : "Before visiting should be set to clang::getNullCursor()"
*>
struct FieldsVisitData
{
  CXCursor          prev_inline;
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
  GlobalVisitData*  g;
  String            enum_name;
  bool              is_unsigned;
}

// --- Writers Data

enum WriteAttrKind : char (String str, bool has_arg)
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

/// --- Helper modules

macro WriteAttrs* WriteAttrs.init(
  &self, 
  Allocator alloc)
{
  self.kinds.init(alloc, 2);
  self.args.init(alloc, 1);
  return self;
}

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

fn bool BGModuleWrap.equals(
  &self, 
  BGModuleWrap* other)
{
  return self.if_condition == other.if_condition;
}


