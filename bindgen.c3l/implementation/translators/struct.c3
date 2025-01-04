
module bindgen::bg @private;
import std::io, clang;

<*
 Translates structure declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_STRUCT_DECL "Cursor must point to structure declaration"
 @returns "Number of bytes written"
*>
fn usz! transStruct(
  GlobalVisitData* vd,
  CXCursor cursor)
@maydiscard
{
  @pool() {
    StructVisitData vd_struct = {
      .g = vd,
    };

    vd_struct.fields.temp_init(4);
  
    // Translate function parameters and store them into vd_struct.fields
    clang::visitChildren(cursor, &visitorStruct, (CXClientData) &vd_struct);
    
    CXString cursor_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(cursor_spell);

    return writeStruct(
      vd.out,
      vd_struct.fields.array_view(),
      cursor_spell.toString().trans(vd.trans_fns.type) 
    );
  };
}

