
module bindgen::impl::misc @private;
import bindgen::impl @public;
import clang, std::io;

faultdef NOT_BASIC_TYPE;

fn String convStr(
  CXString s) 
@inline
{
  return clang::getCString(s).str_view();
}

<*
 Behaviour of clang::getCursorExtent is a bit broken. If some macro
 is expanded under the following cursor, beginning of the given range
 will point to the macro definition. Apparently, clang::getExpansionLocation
 fixes that bug. I love libclang :)
*>
fn CXSourceRange getTrueCursorExtent(
  CXCursor cursor)
{
  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
  CXSourceRange sr = clang::getCursorExtent(cursor);
  CXSourceLocation sl_begin = clang::getRangeStart(sr);    
  CXSourceLocation sl_end = clang::getRangeEnd(sr);
  CXFile file; CUInt offset; 
  clang::getExpansionLocation(sl_begin, &file, null, null, &offset);
  sl_begin = clang::getLocationForOffset(tu, file, offset); 
  sr = clang::getRange(sl_begin, sl_end);

  return sr;
}

<*
 Literally iterates through CXToken[] automatically converting them to strings it
*>
macro @iterateTokens(
  CXToken[] tokens, 
  CXTranslationUnit tu; 
  @body(CXToken* token, String token_str))
{
  foreach (&t : tokens) {
    CXString token_spell = clang::getTokenSpelling(tu, *t);
    defer clang::disposeString(token_spell);
    String token_str = misc::convStr(token_spell);

    @body(t, token_str);
  }
}

<*
 Detects whether the type is pointer to function
*>
fn bool isTypePFN(
  CXType type)
{
  return clang::getPointeeType(type).kind == clang::TYPE_FUNCTION_PROTO;
}

<*
 Iterates through the toppest children of cursor and returns
 their quantity
*>
fn usz getTopChildrenNumber(
  CXCursor cursor)
{
  usz qty;

  clang::visitChildren(
    cursor, 
    fn (CXCursor cursor, CXCursor parent, CXClientData client_data)
    {
      usz* qty = (usz*) client_data;
      ++*qty;
      return clang::CHILD_VISIT_CONTINUE;
    },
    (CXClientData) &qty
  );

  return qty;
}

fn CFieldKind getCFieldKind(
  CXCursor cursor)
{
  CFieldKind kind;

  switch (clang::getCursorKind(cursor)) {
    case clang::CURSOR_STRUCT_DECL: 
      kind = STRUCT;
    case clang::CURSOR_UNION_DECL: 
      kind = UNION;
    case clang::CURSOR_ENUM_DECL:
      kind = ENUM;
    default: 
      if (clang::getFieldDeclBitWidth(cursor) == -1) {
        kind = NORMAL;
      } else {
        kind = BIT;
      }
  }

  return kind;
}

<*
 Returns fault if type is not basic
*>
fn String? mapBasicType(String str)
{
  switch (str) {
    case "void":          return "void";
    case "_Bool":         return "bool";
    case "ptrdiff_t":     return "isz";
    case "size_t":        return "usz";

    case "char":          return "CChar";
    case "short":         return "CShort";
    case "int":           return "CInt";
    case "long":          return "CLong";
    case "long long":     return "CLongLong";

    case "unsigned char":       return "char";
    case "unsigned short":      return "CUShort";
    case "unsigned":            return "CUInt";
    case "unsigned int":        return "CUInt";
    case "unsigned long":       return "CULong";
    case "unsigned long long":  return "CULongLong";
    
    case "signed char":       return "ichar";
    case "signed short":      return "CShort";
    case "signed":            return "CUInt";
    case "signed int":        return "CInt";
    case "signed long":       return "CLong";
    case "signed long long":  return "CLongLong";

    case "int8_t":        return "ichar";
    case "int16_t":       return "short";
    case "int32_t":       return "int";
    case "int64_t":       return "long";
    case "intptr_t":      return "iptr";

    case "uint8_t":       return "char";
    case "uint16_t":      return "ushort";
    case "uint32_t":      return "uint";
    case "uint64_t":      return "ulong";
    case "uintptr_t":     return "uptr";

    case "float":         return "float";
    case "double":        return "double";

    case "va_list":       return "void*";

    default:              return NOT_BASIC_TYPE?;
  }
}

fn CXType getBaseType(
  CXType type) 
{
  CXType base;

  while LOOP: (true) {
    switch (type.kind) {
      case clang::TYPE_POINTER: 
        type = clang::getPointeeType(type);

      case clang::TYPE_CONSTANT_ARRAY:
      case clang::TYPE_INCOMPLETE_ARRAY:
        type = clang::getElementType(type);

      default:
        base = type;
        break LOOP;
    }
  }

  return base;
}

