
module bindgen::impl::algo @private;
import bindgen::impl @public; 
import std::collections::list;

faultdef ERROR;

alias RangeStrList @local = List{RangeStr};
struct RangeStr @local
{
  String str;
  usz left;
  usz right;
}

<*
 The algorithm does the following:
 1. Cycles through C fields to especially detect bit fields
 2. During the loop it maps C bit fields to C3 bit structs according to the following logic:
   - If we have a segment of bit fields, we should check their accumulated width in bits
   - Once width is not power of 2, we can't detect the padding as it's implementation-defined, so throw an error
   - Once width is power of 2, we set it in FieldsC3 with underlying type, which size equals to the accumulated width
 3. Then it allocates everything that is needed via an allocator and returns the resulting structure
*>
fn FieldsC3? getC3Fields(Allocator alloc, Fields cfs)
{
  // Calculate length
  usz norm_fields_count;
  foreach (w : cfs.widths[:cfs.len]) if (w == -1) ++norm_fields_count;
  usz bit_fields_count = cfs.len - norm_fields_count;

  // Detect bitstruct ranges
  RangeStrList ranges;
  ranges.tinit(2);
  defer ranges.free();

  usz bit_field_seg;
  CInt acc_bit_width;
  foreach (i, w : cfs.widths[:cfs.len])
  {
    if (w != -1) 
    {
      if (bit_field_seg == 0) bit_field_seg = i;
      acc_bit_width += w;
    }
    else if (acc_bit_width != 0 && bit_field_seg != 0)
    {
      switch (acc_bit_width)
      {
        case 8:
          ranges.push({ .str = "char", .left = bit_field_seg, .right = i });               
        case 16:
          ranges.push({ .str = "ushort", .left = bit_field_seg, .right = i });               
        case 32:
          ranges.push({ .str = "uint", .left = bit_field_seg, .right = i });               
        case 64:
          ranges.push({ .str = "ulong", .left = bit_field_seg, .right = i });               
        case 128:
          ranges.push({ .str = "uint128", .left = bit_field_seg, .right = i });               
        default:
          return algo::ERROR?;
      }

      bit_field_seg = 0;
      acc_bit_width = 0;
    }
  }

  // Analyze ranges
  FieldsC3 res;
  res.norm = allocator::alloc_array(alloc, VarDecl, norm_fields_count);
  res.bit = allocator::alloc_array(alloc, BitStructC3, ranges.len());
  res.kinds = allocator::alloc_array(alloc, FieldC3Kind, res.norm.len + res.bit.len).ptr;

  // Kinds
  {
    usz i;
    usz norm_c;
    usz bit_c;
    foreach (&kind : res.kinds[:res.len()])
    {
      if (cfs.widths[i] == -1)
      {
        res.norm[norm_c] = cfs.vals[i];
        *kind = FieldC3Kind.NORMAL;
        ++i;
        ++norm_c;
      }
      else
      {
        res.bit[bit_c].under_type = ranges[bit_c].str;
        res.bit[bit_c].fields = allocator::alloc_array(alloc, BitFieldC3, ranges[bit_c].right - i);

        CInt prev_width = -1;
        foreach (j, &bitfield : res.bit[bit_c].fields)
        {
          bitfield.val = cfs.vals[i + j];
          bitfield.from = (usz) (prev_width + 1);
          bitfield.to = (usz) (prev_width + cfs.widths[i + j]);

          prev_width = (CInt) bitfield.to;
        }

        *kind = FieldC3Kind.BITSTRUCT;
        while (cfs.widths[i] != -1) ++i;
        ++bit_c;
      }
    }
  }

  return res;
}

