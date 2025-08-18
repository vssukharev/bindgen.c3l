<*
 All data types are defined here
*>
module bgimpl;
import bindgen::bg,
       std::io, 
       std::collections::map, 
       std::collections::list, 
       clang;


<*
 NORMAL - regular field
 BIT - bit field
 STRUCT - inlined struct
 UNION - inlined union
 ENUM - inlined enum
*>
enum CFieldKind : char
{
  NORMAL,
  BIT,
  STRUCT,
  UNION,
  ENUM,
}


<*
 NORMAL - regular field
 BITSTRUCT - inlined bitstruct
 STRUCT - inlined struct
 UNION - inlined union
*>
enum C3FieldKind : char
{
  NORMAL,
  BITSTRUCT,
  STRUCT,
  UNION
}


<*
 NAME - 'struct' or 'MyType'
 POINTER - *
 SIZED_ARRAY - [10]
 UNSIZED_ARRAY  - []
*>
enum CTypeTokenKind : char
{
  NAME,
  POINTER,
  SIZED_ARRAY,  
  UNSIZED_ARRAY,
}


<*
 Represents the C3 declaration kind,
 written to out file
*>
enum WriteKind
{
  ALIAS, TYPEDEF,
  FUNC, CONST, 
  UNION, ENUM,
  MACRO, MODULE,
  IMPORT, STRUCT,
  VAR, BITSTRUCT,
}


<*
 Represents attributes for C3 declarations
 has_arg - whether an attr
*>
enum WriteAttrKind : char (String str, bool has_arg)
{
  PRIVATE = { "@private", false },
  IF      = { "@if"     , true  },
}


<*
 Types translation table maps CXType to C3 name. 
*>
alias TypesTable = HashMap{CXType, String};


<*
 Represents variable declaration meaning:
 <type> <name>;
*>
struct VarDecl
{
  String type;
  String name;
}


<*
 Represents bit fields meaning:
 <type> <name> : <width>;
*>
struct CBitField
{
  String  type;
  String  name;
  usz     width;
}


<*
 Represents anonymous structure meaning:

 name : "Optional, can be zero string"
*>
struct CInlinedRecord
{
  String  name;
  CFields fields;
}


<* 
 kinds.len == sum of *.len 
*>
struct CFields
{
  List{CFieldKind}      kinds;
  List{VarDecl}         norm;
  List{CBitField}       bit;
  List{CInlinedRecord}  structs;
  List{CInlinedRecord}  unions;
}


<*
 name : "Optional, can be zero string"
*>
struct C3InlinedRecord
{
  C3Fields  fields;
  String    name;
}


<*
 under_type : "Underlying type of a bitstruct (bitstruct : under_type { ... })"
*>
struct C3InlinedBitstruct
{
  List{C3BitstructField}  fields;
  String                  under_type;
}


<*
 from : "Number of starting bit"
 to : "Number of ending bit"
*>
struct C3BitstructField
{
  String  type;
  String  name;
  usz     from;
  usz     to;
}


<* 
  kinds.len == sum of *.len 
*>
struct C3Fields
{
  List{C3FieldKind}         kinds;
  List{VarDecl}             norm;
  List{C3InlinedBitstruct}  bit;
  List{C3InlinedRecord}     structs;
  List{C3InlinedRecord}     unions;
}


<*
 strs : "Strings, which are unknown at compile time"
*>
struct CTypeTokens
{
  List{CTypeTokenKind} kinds;
  List{String}         strs;
}



<*
 Visit data, accesed from any visitor

 cxfile : "Used to ignore nodes from other files "
*>
struct GlobalVisitData
{
  BGTransCallbacks  trans_fns;
  BGGenCallbacks    gen_fns;
  BGCheckFn         include_file;
  String            module_name;
  BGModuleWrap      prev_module_wrap;

  TypesTable        types_table;
  File*             out;
  CXFile            cxfile;
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
  List{VarDecl}     params;
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


<*
 is_incomplete : "Whether the underlying type is incomplete"
*>
struct TypedefVisitData
{
  GlobalVisitData*  g;
  CXType            under_type;
  bool              is_incomplete;
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


<*
 Writing state, passed to the writers
*>
struct WriteState
{
  WriteKind kind;
}


<*
 Only kind with kind.has_arg can have an arg
*>
struct WriteAttrs (Printable)
{
  List{WriteAttrKind} kinds;
  List{String}        args;
}

