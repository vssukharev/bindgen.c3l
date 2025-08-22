<*
 This module contains independent pure helper functions
 or macros with minimal logic, which are frequently 
 used across the codebase.
*>
module bgimpl::misc;
import bgimpl, 
       clang, 
       std::collections::list;

<*
 Convert CXString to a regular C3 String, without the need
 of addiitional allocations. Note, that String becomes
 invalid when the original CXString is disposed.
*>
fn String convStr(CXString s) @inline => clang::getCString(s).str_view();


<*
 Detects whether the type is a pointer to function or function
 itself
*>
fn bool isTypePFN(CXType type) @inline
{
  if (type.kind == clang::TYPE_POINTER) {
    type = clang::getPointeeType(type);
  }
  return type.kind == clang::TYPE_FUNCTION_PROTO || type.kind == clang::TYPE_FUNCTION_NO_PROTO;
}

<*
 If the cursor does not represent a definition of that cursor,
 we consider it forwardly declared
*>
fn bool isCursorForwardDeclared(CXCursor cursor) @inline => !clang::isCursorDefinition(cursor);


<*
 Type is incomplete in case when it can't be used directly, without
 a pointer to it
*>
fn bool isTypeIncomplete(CXType type) @inline => clang::getSizeOf_Type(type) == clang::TYPE_LAYOUT_ERROR_INCOMPLETE;


<*
 getTrueCursorExtent returns a source range for the cursor without
 preprocessor 'location jumps' when doing regular clang::getCursorExtent.
 
 Behaviour of clang::getCursorExtent is a bit weird. If some macro
 is expanded under the following cursor, beginning of the given range
 will point to the macro definition. clang::getExpansionLocation
 fixes that bug as it considers macro expansion part as a regular token,
 without doing these 'location jumps'.
*>
fn CXSourceRange getTrueCursorExtent(
  CXCursor cursor)
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
 Iterates through the cursor's toppest children and returns
 their quantity. Does not skip attributes, macro expansions,
 etc.
*>
fn usz getTopChildrenNumber(
  CXCursor cursor)
{
  usz qty;

  clang::visitChildren(cursor, 
    fn (CXCursor cursor, CXCursor parent, CXClientData client_data) {
      usz* qty = (usz*) client_data;
      ++*qty;
      return clang::CHILD_VISIT_CONTINUE;
    }, (CXClientData) &qty
  );

  return qty;
}


<*
 If type is a nested pointer or array, gets rid
 of these qualifiers and returns the basic type.
*>
fn CXType getBaseType(
  CXType type) 
{
  CXType base;

  while LOOP: (true) {
    switch (type.kind) {
      case clang::TYPE_POINTER: 
        type = clang::getPointeeType(type);

      case clang::TYPE_CONSTANT_ARRAY:
      case clang::TYPE_INCOMPLETE_ARRAY:
        type = clang::getElementType(type);

      default:
        base = type;
        break LOOP;
    }
  }

  return base;
}

