<*
 This module contains independent pure helper functions
 or macros with minimal logic, which are frequently 
 used across the codebase.
*>
module bgimpl::misc;
import bgimpl, 
       clang, 
       std::collections::list;

// --- WHAT WON'T WORK
// macro int.@foreach(self) {}

<*
 Convert CXString to regular C3 String
*>
fn String convStr(CXString s) @inline => clang::getCString(s).str_view();


<*
 Detects whether the type is pointer to function
*>
fn bool isTypePFN(CXType type) @inline => clang::getPointeeType(type).kind == clang::TYPE_FUNCTION_PROTO;


<*
 If the cursor does not represent a definition of that cursor,
 we consider it forwardly declared
*>
fn bool isCursorForwardDeclared(CXCursor cursor) @inline => !clang::isCursorDefinition(cursor);


<*
 Helper function for clang functionality
*>
fn bool isTypeIncomplete(CXType type) @inline => clang::getSizeOf_Type(type) == clang::TYPE_LAYOUT_ERROR_INCOMPLETE;


<*
 Behaviour of clang::getCursorExtent is a bit broken. If some macro
 is expanded under the following cursor, beginning of the given range
 will point to the macro definition. Apparently, clang::getExpansionLocation
 fixes that bug. I love libclang :)
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
 Iterates through the toppest children of cursor and returns
 their quantity
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

