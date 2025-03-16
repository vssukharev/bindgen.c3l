
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

struct StructVisitData
{
  VarDeclList fields;
  Allocator allocator;
  GlobalVisitData* g;
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
  GlobalVisitData* g;
  EnumVals vals;
  usz current;
  bool is_unsigned;
}

