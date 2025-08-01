
// TODO: move everything to 'bindgen::impl::misc'
module bindgen::impl::algo @private;
import bindgen::impl @public; 
import std::collections::list, clang;

faultdef ERROR;

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
        CFieldBit cfield = cfs.bit[index];
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
          return algo::ERROR?;
      }

      bit_fields = {};
      bit_fields.init(alloc);
      bit_segment_start = usz.max;
    }
  };

  return res;
}



