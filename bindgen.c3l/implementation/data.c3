
module bindgen::bg @private;
import std::io, std::collections::map, std::collections::list;

<*
 Translation tables maps C name to C3 name. 
 For instance: { .key = "int", .val = "CInt"} or "int" -> "CInt".
*>
def TransTable = Map(<String, String>);

struct GlobalVisitData
{
  BGTransCallbacks trans_fns;
  TransTable types_table;
  File* out;
}

def VarDeclList = List(<VarDecl>);
struct VarDecl
{
  String type;
  String name;
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

