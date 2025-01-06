
module bindgen::bg @private;
import std::io, clang;

<*
 Translates enumeration declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_ENUM_DECL "Cursor must point to enum declaration"
 @returns "Number of bytes written"
*>
fn usz! transEnum(
  GlobalVisitData* vd,
  CXCursor cursor)
@maydiscard
{
  @pool()
  {
    CXType enum_name = clang::getCursorType(cursor);
    String enum_str = enum_name.ttrans(vd.trans_fns.type, &vd.types_table);

    CXType enum_type = clang::getEnumDeclIntegerType(cursor);
    String enum_type_str = enum_type.ttrans(vd.trans_fns.type, &vd.types_table);
  
    // Get values quantity
    usz values_len;
    clang::visitChildren(
      cursor, 
      fn CXChildVisitResult(CXCursor cursor, CXCursor parent, CXClientData client_data)
      {
        usz* values_len = (usz*) client_data;
        ++*values_len;
        return clang::CHILD_VISIT_CONTINUE;
      },
      (CXClientData) &values_len
    );

    @pool()
    {
      EnumVisitData vd_enum = {
        .g = vd,
        .vals = {
          .names = mem::temp_new_array(String, values_len).ptr,
          .rhses = mem::temp_new_array(DString, values_len).ptr,
          .len = values_len,
        }
      };

      for (usz i; i < vd_enum.vals.len; ++i)
      {
        vd_enum.vals.rhses[i].temp_init();
      }

      switch (enum_type.kind)
      {
        case clang::TYPE_UCHAR:
        case clang::TYPE_USHORT: 
        case clang::TYPE_UINT:      
        case clang::TYPE_ULONG:
        case clang::TYPE_ULONGLONG: 
          vd_enum.is_unsigned = true;
        default:
          vd_enum.is_unsigned = false;
      }

      clang::visitChildren(cursor, &visitorEnum, (CXClientData) &vd_enum);

      return writeEnum(vd.out, enum_str, enum_type_str, vd_enum.vals);
    };
  };
}


