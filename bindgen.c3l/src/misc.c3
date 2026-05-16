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


fn String getCursorDoc(CXCursor cursor, Allocator alloc, int indent = 0) {
  CXString raw = clang::cursor_getRawCommentText(cursor);
  
  if (raw.data == null) {
      return ""; 
  }

  defer clang::disposeString(raw);
  String conv_str = misc::convStr(raw).copy(alloc); 
	return cleanupDoc(alloc, conv_str, indent);
}

fn String cleanupDoc(Allocator alloc, String raw_doc, int indent_level = 0) => @pool() {
  if (raw_doc.len == 0) return "";

  DString clean;
  clean.tinit();

	DString indent_builder;
  indent_builder.tinit();
  for (int i = 0; i < indent_level; i++) {
      indent_builder.append("  ");
  }
  String indent = indent_builder.str_view();
  
  // Split the raw comment into lines
  String[] lines = raw_doc.split(tmem, "\n");
    
	clean.append(indent);
  clean.append("<*\n");
    
  foreach (line : lines) {
    String trimmed = line.trim();
    
    // Remove comment start, end, and leading asterisks
    if (trimmed.starts_with("/**")) { 
      trimmed = trimmed[3..]; 
    }
    else if (trimmed.starts_with("/*")) {
      trimmed = trimmed[2..];
    }
    if (trimmed.ends_with("*/")) { 
      trimmed = trimmed[..trimmed.len - 2];
    }
      
    // Strip the leading '*' if it exists (standard Doxygen style)
    trimmed = trimmed.trim();
    if (trimmed.starts_with("*")) {
      trimmed = trimmed[1..].trim();
    }

    if (trimmed.len > 0) {
    clean.append(indent);
      clean.append("  "); // Indent for style
      clean.append(trimmed);
      clean.append("\n");
    }
  }
    
	clean.append(indent);
  clean.append("*>");
  return clean.copy_str(alloc);
}

<*
 Detects whether the type is a pointer to function or function
 itself
*>
fn bool isTypePFN(CXType type) @inline
{
	if (type.kind == TYPE_POINTER) {
		type = clang::getPointeeType(type);
	}
	return type.kind == TYPE_FUNCTION_PROTO || type.kind == TYPE_FUNCTION_NO_PROTO;
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
fn bool isTypeIncomplete(CXType type) @inline 
{
	// If layout explicitly says it is incomplete, it is incomplete.
	if ((CInt)clang::type_getSizeOf(type) == (CInt)CXTypeLayoutError.TYPE_LAYOUT_ERROR_INCOMPLETE) {
		return true;
	}

	// check if the declaration declaration lacks a definition
	CXCursor declaration = clang::getTypeDeclaration(type);
	CXCursorKind kind = clang::getCursorKind(declaration);

	if (kind == CURSOR_STRUCT_DECL || 
		kind == CURSOR_UNION_DECL || 
		kind == CURSOR_ENUM_DECL) {
		return clang::isCursorDefinition(declaration) == 0;
	}

	return false;
}

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
	CXTranslationUnit tu = clang::cursor_getTranslationUnit(cursor);
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
	sz qty;

	clang::visitChildren(cursor, 
		fn (CXCursor cursor, CXCursor parent, CXClientData client_data) {
		sz* qty = (sz*) client_data;
		++*qty;
		return CHILD_VISIT_CONTINUE;
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
		case TYPE_POINTER: 
			type = clang::getPointeeType(type);

		case TYPE_CONSTANT_ARRAY:
		case TYPE_INCOMPLETE_ARRAY:
			type = clang::getElementType(type);

      default:
        base = type;
        break LOOP;
    }
  }

  return base;
}

