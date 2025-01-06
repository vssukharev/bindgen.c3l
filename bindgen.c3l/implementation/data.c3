
module bindgen::bg @private;
import std::io, std::collections::map, std::collections::list;

// --- Helper Structures

<*
 Translation table maps C name to C3 name. 
 For instance: { .key = "int", .val = "CInt" } is "int" -> "CInt".
*>
def TransTable = Map(<String, String>);

def VarDeclList = List(<VarDecl>);

struct VarDecl
{
  String type;
  String name;
}

struct EnumVals
{
  DString* rhses;
  String* names;
  usz len;
}

// --- Visit Data

struct GlobalVisitData
{
  BGTransCallbacks trans_fns;
  TransTable types_table;
  TransTable consts_table;
  File* out;
}

struct FuncVisitData
{
  VarDeclList params;
  GlobalVisitData* g;
}

struct StructVisitData
{
  VarDeclList fields;
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
}

struct EnumVisitData
{
  GlobalVisitData* g;
  EnumVals vals;
  usz current;
  bool is_unsigned;
}

struct EnumValVisitData
{
  GlobalVisitData* g;
  DString* rhs;
}

struct MacroVisitData
{
  DString val;
  GlobalVisitData* g;
}

