<*
 The module consists of functions, which
 perform conversions from clang or user-defined
 structures, representing types, to more 
 applicable form
*>
module bgimpl::tparse;
import clang, 
       bgimpl, 
       std::collections::list;


faultdef INVALID_BITFIELDS;


<*
 Converts token kind to it's representation in C3.
 If kind is represented with a run-time string, strs
 and str_index are used to retrieve this string.
*>
fn String convertCTypeTokenToC3(
  CTypeTokenKind kind,
  String[] strs,
  usz str_index)
  @inline
{
  switch (kind) {
    case NAME:
    case SIZED_ARRAY:
      assert( str_index < strs.len );
      return strs[str_index];
    case UNSIZED_ARRAY:
    case POINTER:
      return "*";
  }
}

<*
 Converts type to CTypeTokens in reversed order.
 Automatically strips all type qualifiers, like 
 "struct", "const", etc.
 Example: int[10]* -> [*, [10], int]
 @return "CTypeTokens, allocated via alloc"
*>
fn CTypeTokens getTypeTokens(
  Allocator alloc, 
  CXType type)
{
  CTypeTokens tokens;
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
 Converts CFields to C3Fields:
 1. Cycles through C fields to especially detect bit fields
 2. During the loop it maps C bit fields to C3 bit structs according to the following logic:
   - If we have a segment of bit fields, we should check their accumulated width in bits
   - Once width is not power of 2, we can't detect the padding as it's implementation-defined, so throw an error
   - Once width is power of 2, we set it in C3Fields with underlying type, which size equals to the accumulated width
 3. Then it allocates everything that is needed via an allocator and returns the resulting structure
 @return? tparse::INVALID_BITFIELDS
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
  List{C3BitstructField} bit_fields;
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
        bit_fields.push({
          .type = cfield.type, 
          .name = cfield.name, 
          .from = bit_widths_acc, 
          .to = bit_widths_acc + cfield.width - 1
        });
        bit_widths_acc += cfield.width;

      case STRUCT:
        res.kinds.push(STRUCT);
        C3Fields c3fields = getC3Fields(alloc, cfs.structs[index].fields)!;
        res.structs.push({
          .name = cfs.structs[index].name, 
          .fields = c3fields,
        });

      case UNION:
        res.kinds.push(UNION);
        C3Fields c3fields = getC3Fields(alloc, cfs.unions[index].fields)!;
        res.unions.push({
          .name = cfs.unions[index].name, 
          .fields = c3fields,
        });
      }

    // Finish bit range and reset things if needed
    if ((*kind != BIT || index == cfs.bit.len() - 1) && bit_segment_start != usz.max) {
      res.kinds.push(BITSTRUCT);
      switch (bit_widths_acc) {
        case 1..8:
          res.bit.push({
            .under_type = "char", 
            .fields = bit_fields
          });
        case 9..16:
          res.bit.push({
            .under_type = "ushort", 
            .fields = bit_fields
          });
        case 17..32:
          res.bit.push({
            .under_type = "uint", 
            .fields = bit_fields
          });
        case 33..64:
          res.bit.push({
            .under_type = "ulong", 
            .fields = bit_fields
          });
        case 65..128:
          res.bit.push({
            .under_type = "uint128", 
            .fields = bit_fields
          });
        default:
          return tparse::INVALID_BITFIELDS~;
      }

      bit_fields = {};
      bit_fields.init(alloc);
      bit_segment_start = usz.max;
    }
  };

  return res;
}


<*
 Converts cursor kind to CFieldKind
*>
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


