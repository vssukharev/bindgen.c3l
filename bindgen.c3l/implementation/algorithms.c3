
module bindgen::impl::algo @private;
import bindgen::impl @public; 
import std::collections::list;

faultdef ERROR;

<*
 The algorithm does the following:
 1. Cycles through C fields to especially detect bit fields
 2. During the loop it maps C bit fields to C3 bit structs according to the following logic:
   - If we have a segment of bit fields, we should check their accumulated width in bits
   - Once width is not power of 2, we can't detect the padding as it's implementation-defined, so throw an error
   - Once width is power of 2, we set it in C3Fields with underlying type, which size equals to the accumulated width
 3. Then it allocates everything that is needed via an allocator and returns the resulting structure
*>
fn C3Fields? getC3Fields(Allocator alloc, CFields cfs) => @pool()
{
  C3Fields res;
  res.init(alloc);

  // usz.max means we're not in segment
  usz bit_widths_acc;
  usz bit_segment_start = usz.max;
  List{BitstructMember} bit_fields;
  bit_fields.init(alloc);

  cfs.@foreach(; FieldKind* kind, usz index)
  {
    switch (*kind)
    {
      // TODO: do it without pushes with plain copy 
      // as res.norm practically equal cfs.norm
      case NORMAL:
        res.kinds.push(*kind);
        res.norm.push(cfs.norm[index]);

      case BIT:
        CFieldBit cfield = cfs.bit[index];
        if (bit_segment_start == usz.max) bit_segment_start = index;
        bit_fields.push({cfield.type, cfield.name, bit_widths_acc, bit_widths_acc + cfield.width - 1});
        bit_widths_acc += cfield.width;

      case STRUCT:
        res.kinds.push(*kind);
        C3Fields c3fields = getC3Fields(alloc, cfs.structs[index].fields)!;
        res.structs.push({cfs.structs[index].name, c3fields});

      case UNION:
        res.kinds.push(*kind);
        C3Fields c3fields = getC3Fields(alloc, cfs.unions[index].fields)!;
        res.unions.push({cfs.unions[index].name, c3fields});
    }

    // Finish bit range and reset things if needed
    if ((*kind != BIT || index == cfs.bit.len() - 1) && bit_segment_start != usz.max)
    {
      res.kinds.push(BIT);
      switch (bit_widths_acc)
      {
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

