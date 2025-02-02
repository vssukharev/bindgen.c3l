
module bindgen::bg @private;
import std::io, clang;

<*
 Visits enum values
*>
fn CXChildVisitResult visitorEnum(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  EnumVisitData* vd = (EnumVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = cursor_spell.toString();
  vd.vals.names[vd.current] = cursor_str.newTrans(vd.g.trans_fns.constant); // TODO: get rid of leak 

  ConstVisitData vd_const = {
    .g = vd.g,
  };

  vd_const.val.new_init();
  defer vd_const.val.free();

  clang::visitChildren(cursor, &visitorConst, (CXClientData) &vd_const);

  // If we get empty rhs, evaluate value
  if (vd_const.val.str_view() == "")
  {
    if (vd.is_unsigned)
    {
      CULongLong ival = clang::getEnumConstantDeclUnsignedValue(cursor);
      vd_const.val.appendf("%s", ival);
    }
    else
    {
      CLongLong ival = clang::getEnumConstantDeclValue(cursor);
      vd_const.val.appendf("%s", ival);
    }
  }

  vd.vals.rhses[vd.current] = vd_const.val.copy_str(); // TODO: get rid of leak

  ++vd.current;
  return clang::CHILD_VISIT_CONTINUE;
}

