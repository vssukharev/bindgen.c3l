
module bindgen::bg @private;
import std::io, clang;

<*
 Translates enumeration declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_ENUM_DECL "Cursor must point to enum declaration"
 @returns "Number of bytes written"
*>
fn usz! transWriteEnum(GlobalVisitData* vd, CXCursor cursor) @maydiscard
{
  @pool()
  {
    CXType type = clang::getCursorType(cursor);
    String type_str = type.transCache(vd.trans_fns.type, &vd.types_table);

    CXType under_type = clang::getEnumDeclIntegerType(cursor);
    String under_type_str = under_type.transCache(vd.trans_fns.type, &vd.types_table);
  
    // Get values length
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
          .rhses = mem::temp_new_array(String, values_len).ptr,
          .len = values_len,
        }
      };

      switch (under_type.kind)
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

      return writeEnum(vd.out, type_str, under_type_str, vd_enum.vals);
    };
  };
}


