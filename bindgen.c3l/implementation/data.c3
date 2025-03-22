
// TODO: move to 'bindgen::impl'
module bindgen::bg @private;
import std::io, std::collections::map, std::collections::list, clang;

// --- Helper Structures

<*
 Translation table maps C name to C3 name. 
 For instance: { .key = "int", .val = "CInt" } is "int" -> "CInt".
*>
def TransTable = HashMap{String, String};
def VarDeclList = List{VarDecl};

struct VarDecl
{
  String type;
  String name;
}

struct EnumVals
{
  String* rhses;
  String* names;
  usz len;
}

struct Fields
{
  VarDecl* vals;
  CInt* widths; // bit field width. If widths[i] == -1 then it's not a bit field
  usz len;
}

struct FieldsC3
{
  FieldC3Kind* kinds;
  VarDecl[] norm;
  BitStructC3[] bit;
}

fn usz FieldsC3.len(&self) @inline => self.norm.len + self.bit.len; 

enum FieldC3Kind : char
{
  NORMAL, BITSTRUCT
}

struct BitStructC3
{
  String under_type; // bitstruct : under_type { ... }
  BitFieldC3[] fields;
}

struct BitFieldC3
{
  VarDecl val;
  usz from;
  usz to;
}

// --- Visit Data

struct GlobalVisitData
{
  BGTransCallbacks trans_fns;
  TransTable types_table;
  File* out;
  CXFile cxfile; // used to ignore nodes from other files 
}

// 'allocator' is for VarDecl.name allocations
struct FuncVisitData
{
  VarDeclList params;
  Allocator allocator;  
  GlobalVisitData* g;
}

struct FieldsVisitData
{
  Fields fields;
  Allocator allocator;
  GlobalVisitData* g;
  usz current;
}

struct TypedefVisitData
{
  GlobalVisitData* g;
}

struct ConstVisitData
{
  DString val;
  GlobalVisitData* g;
  usz current;
}

struct EnumVisitData
{
  EnumVals vals;
  GlobalVisitData* g;
  usz current;
  bool is_unsigned;
}

