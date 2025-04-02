
module bindgen::impl::misc @private;
import bindgen::impl @public;
import clang, std::io;

fn String convStr(CXString s) @inline
{
  return clang::getCString(s).str_view();
}

<*
 Behaviour of clang::getCursorExtent is a bit broken. If some macro
 is expanded under the following cursor, beginning of the given range
 will point to the macro definition. Apparently, clang::getExpansionLocation
 fixes that bug. I love libclang :)
*>
fn CXSourceRange getTrueCursorExtent(CXCursor cursor)
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
 Literally iterates through CXToken[] automatically converting them to strings it
*>
macro @iterateTokens(CXToken[] tokens, CXTranslationUnit tu; @body(CXToken* token, String token_str))
{
  foreach (&t : tokens)
  {
    CXString token_spell = clang::getTokenSpelling(tu, *t);
    defer clang::disposeString(token_spell);
    String token_str = misc::convStr(token_spell);

    @body(t, token_str);
  }
}

<*
 Detects whether the type is pointer to function
*>
fn bool isTypePFN(CXType type)
{
  return clang::getPointeeType(type).kind == clang::TYPE_FUNCTION_PROTO;
}

<*
 Iterates through the toppest children of cursor and returns
 their quantity
*>
fn usz getTopChildrenNumber(CXCursor cursor)
{
  usz qty;

  clang::visitChildren(
    cursor, 
    fn CXChildVisitResult(CXCursor cursor, CXCursor parent, CXClientData client_data)
    {
      usz* qty = (usz*) client_data;
      ++*qty;
      return clang::CHILD_VISIT_CONTINUE;
    },
    (CXClientData) &qty
  );

  return qty;
}

<*
 Retrives FieldKind from a cursor
*>
fn FieldKind getFieldKind(CXCursor cursor)
{
  FieldKind kind;

  switch (clang::getCursorKind(cursor)) 
  {
    case clang::CURSOR_STRUCT_DECL: 
      kind = STRUCT;

    case clang::CURSOR_UNION_DECL: 
      kind = UNION;

    default: 
      if (clang::getFieldDeclBitWidth(cursor) == -1) 
      {
        kind = NORMAL;
      }
      else
      {
        kind = BIT;
      }
  }

  return kind;
}

