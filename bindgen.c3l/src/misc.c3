
<*
 This module contains independent pure helper functions
 or macros with minimal logic, which are frequently 
 used across the codebase.

 Leave: convStr, isTypePFN, getTrueCursorExtent, 
        getTopChildrenNumber, isCursorForwardDeclared,
        getBaseType, isTypeIncomplete

 Get rid of: convertLiteral, getTypeTokens, @iterateTokens,
             getC3Fields, getCFieldKind, mapBasicType
*>
module bgimpl::misc;
import bgimpl,
       clang, 
       std::io,
       std::collections::list;

faultdef NOT_BASIC_TYPE, INVALID_BITFIELDS;

<*
*>
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
fn String? mapBasicType(
  String str)
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


<*
 Converts C integer or floating-point literal epressions to C3 ones
*>
fn String convertLiteral(
  Allocator alloc,
  String str)
=> @pool()
{
  // If it's a string or empty literal
  if (str.len == 0 || str[0] == '"') return str;

  bool is_float = @ok(str.index_of_char('.'));
  DString res = dstring::temp(str);

  // --- Prefixes (octal)
  if (str.len >= 2 && str[0] == '0' && str[1].is_odigit()) {
    res.insert_at(1, 'o');
  }

  // --- Suffixes
  res.replace("LL", "L");
  res.replace("ll", "l");
  
  // C3 doesn't have 'L' or 'l' literals for float so substitute them with ""
  if (is_float) {
    res.replace("L", "");
    res.replace("l", "");
  }

  return res.copy_str(alloc);
}

fn TypeTokens getTypeTokens(
  Allocator alloc, 
  CXType type)
{
  TypeTokens tokens;
  tokens.init(alloc);

  while LOOP: (true) {
    switch (type.kind) {
      case clang::TYPE_POINTER: 
        tokens.push(POINTER);
        type = clang::getPointeeType(type);

      case clang::TYPE_CONSTANT_ARRAY:
        CLongLong size = clang::getArraySize(type);
        String str = string::format(tmem, "[%d]", size);
        tokens.push(SIZED_ARRAY, str);
        type = clang::getElementType(type);

      case clang::TYPE_INCOMPLETE_ARRAY:
        tokens.push(UNSIZED_ARRAY);
        type = clang::getElementType(type);

      default:
        CXString type_spell = clang::getTypeSpelling(type);
        defer clang::disposeString(type_spell);
        String type_str = misc::convStr(type_spell);

        type_str = type_str.strip("const ").strip("struct ").strip("enum ").strip("union ");
        tokens.push(NAME, type_str.copy(tmem));
        break LOOP;
    }
  }

  return tokens;
}

<*
 The algorithm does the following:
 1. Cycles through C fields to especially detect bit fields
 2. During the loop it maps C bit fields to C3 bit structs according to the following logic:
   - If we have a segment of bit fields, we should check their accumulated width in bits
   - Once width is not power of 2, we can't detect the padding as it's implementation-defined, so throw an error
   - Once width is power of 2, we set it in C3Fields with underlying type, which size equals to the accumulated width
 3. Then it allocates everything that is needed via an allocator and returns the resulting structure

 @return? INVALID_BITFIELDS
*>
fn C3Fields? getC3Fields(
  Allocator alloc, 
  CFields cfs) 
=> @pool()
{
  C3Fields res;
  res.init(alloc);

  // usz.max means we're not in segment
  usz bit_widths_acc;
  usz bit_segment_start = usz.max;
  List{BitstructMember} bit_fields;
  bit_fields.init(alloc);

  cfs.@foreach(; CFieldKind* kind, usz index) {
    switch (*kind) {
      // TODO: do it without pushes with plain copy 
      // as res.norm practically equals to cfs.norm
      case NORMAL:
      case ENUM:
        res.kinds.push(NORMAL);
        res.norm.push(cfs.norm[index]);

      case BIT:
        CBitField cfield = cfs.bit[index];
        if (bit_segment_start == usz.max) bit_segment_start = index;
        bit_fields.push({cfield.type, cfield.name, bit_widths_acc, bit_widths_acc + cfield.width - 1});
        bit_widths_acc += cfield.width;

      case STRUCT:
        res.kinds.push(STRUCT);
        C3Fields c3fields = getC3Fields(alloc, cfs.structs[index].fields)!;
        res.structs.push({cfs.structs[index].name, c3fields});

      case UNION:
        res.kinds.push(UNION);
        C3Fields c3fields = getC3Fields(alloc, cfs.unions[index].fields)!;
        res.unions.push({cfs.unions[index].name, c3fields});
    }

    // Finish bit range and reset things if needed
    if ((*kind != BIT || index == cfs.bit.len() - 1) && bit_segment_start != usz.max) {
      res.kinds.push(BITSTRUCT);
      switch (bit_widths_acc) {
        case 1..8:
          res.bit.push({"char", bit_fields});
        case 9..16:
          res.bit.push({"ushort", bit_fields});
        case 17..32:
          res.bit.push({"uint", bit_fields});
        case 33..64:
          res.bit.push({"ulong", bit_fields});
        case 65..128:
          res.bit.push({"uint128", bit_fields});
        default:
          return INVALID_BITFIELDS?;
      }

      bit_fields = {};
      bit_fields.init(alloc);
      bit_segment_start = usz.max;
    }
  };

  return res;
}

<*
 If the cursor does not represent a definition of that cursor,
 we consider it forwardly declared
*>
macro bool isCursorForwardDeclared(
  CXCursor cursor)
{
  return !clang::isCursorDefinition(cursor);
}


macro bool isTypeIncomplete(
  CXType type)
{
  return clang::getSizeOf_Type(type) == clang::TYPE_LAYOUT_ERROR_INCOMPLETE;
}

// --- WHAT WON'T WORK
// macro CXToken[].@foreach(self; @body(/*...*/)) {}

// --- WHAT WILL WORK
// typedef CXTokenSlice = CXToken[];
// macro CXTokenSlice.@foreach(self; @body(/*...*/)) {}

// --- WHAT WILL WORK: refer to src/translators.c3:6

