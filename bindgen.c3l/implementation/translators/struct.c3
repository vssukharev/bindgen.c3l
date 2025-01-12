
module bindgen::bg @private;
import std::io, clang;

<*
 Translates structure declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_STRUCT_DECL "Cursor must point to structure declaration"
 @returns "Number of bytes written"
*>
fn usz! transWriteStruct(GlobalVisitData* vd, CXCursor cursor) @maydiscard
{
  @pool() {
    String type_name = clang::getCursorType(cursor).transCache(vd.trans_fns.type, &vd.types_table);

    StructVisitData vd_struct = {
      .g = vd,
      .allocator = allocator::temp(),
    };

    vd_struct.fields.temp_init(4);
  
    // Translate function parameters and store them into vd_struct.fields
    clang::visitChildren(cursor, &visitorStruct, (CXClientData) &vd_struct);

    // If no fields are defined, type is incomplete
    if (vd_struct.fields.len() == 0) return writeAliasTypedef(vd.out, type_name, "void");

    return writeStruct(vd.out, vd_struct.fields.array_view(), type_name);
  };
}

