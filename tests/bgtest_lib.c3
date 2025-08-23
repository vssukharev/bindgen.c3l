
module bgtest;
import bgimpl,
       clang,
       std::io,
       std::collections::elastic_array,
       std::collections::list;


const HEADER_NAME @local    = "bgtest-parse.h";
const TUS_CAPACITY @local   = 6;


faultdef PARSE_FAILURE, DIAGS_FAILURE;


<*
 Parses the code and returns cursors, pointing to top-level declarations
 @param alloc         : "Allocator, which allocates CXCursor[]"
 @param code          : "Code to be parse"
 @param extra_args    : "Arguments to clang compiler"
 @param min_severity  : "Minimal severity for diagnostics"
 @param quiet         : "If true, suppress diagnostics messages"
 @return? DIAGS_FAILURE, PARSE_FAILURE
*>
fn CXCursor[]? parse(
  Allocator alloc, 
  char[] code,
  ZString[] extra_args = {},
  CXDiagnosticSeverity min_severity = clang::DIAGNOSTIC_ERROR,
  bool quiet = false)
  => @pool()
{
  const PARSE_FLAGS = 
    clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD |
    clang::TRANSLATION_UNIT_SKIP_FUNCTION_BODIES |
    clang::TRANSLATION_UNIT_KEEP_GOING;

  // Create temp header
  Path tmp = path::temp_directory(tmem)!!;
  tmp = tmp.tappend(HEADER_NAME)!!;
  file::save(tmp.str_view(), code)!!;

  // Get args
  List{ZString} args_list;
  args_list.tinit(extra_args.len+1);
  defer args_list.free();
  args_list.push_all(extra_args);
  args_list.push("-xc");

  ZString[] args = args_list.array_view();

  // Parse file
  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);
  CXTranslationUnit tu = clang::parseTranslationUnit(index, (ZString)tmp.str_view(), args.ptr, args.len, null, 0, PARSE_FLAGS);
  
  // Check the parse result
  if (tu == null) return PARSE_FAILURE?;
  
  // Run diagnostics
  usz severe_count;
  for (CUInt i; i < clang::getNumDiagnostics(tu); ++i) {
    CXDiagnostic diag = clang::getDiagnostic(tu, i); 
    defer clang::disposeDiagnostic(diag);

    CXSourceLocation diag_loc = clang::getDiagnosticLocation(diag);
    CUInt line, col;
    clang::getFileLocation(diag_loc, null, &line, &col, null);

    CXString diag_spell = clang::getDiagnosticSpelling(diag);
    defer clang::disposeString(diag_spell);
    String diag_str = clang::getCString(diag_spell).str_view();

    if (clang::getDiagnosticSeverity(diag) >= min_severity) {
      // Do not count if some file is not found and we don't ignore it
      ++severe_count;
      if (!quiet) io::eprintfn("\e[31mDiagnostic fail at %d:%d\e[0m : %s", line, col, diag_str);
    }
  }
  if (severe_count > 0) return DIAGS_FAILURE?;

  // If we exceeded the size of translation units, collect garbage
  if (translation_units.len() == TUS_CAPACITY) {
    foreach (elem : translation_units) {
      clang::disposeTranslationUnit(elem);
    }
    translation_units.clear();
  }
  translation_units.push(tu);
  
  // Fill the cursors
  List{CXCursor} cursors;
  cursors.tinit();
  defer cursors.free();

  CXCursor top = clang::getTranslationUnitCursor(tu);
  clang::visitChildren(top, fn (cursor, parent, client) {
    // If cursor_file is null, it might be a macro included by a compiler
    CXFile cursor_file;
    clang::getExpansionLocation(clang::getCursorLocation(cursor), &cursor_file, null, null, null);
    if (cursor_file == null) return clang::CHILD_VISIT_CONTINUE;

    // Skip macro expansions
    if (clang::getCursorKind(cursor) == clang::CURSOR_MACRO_EXPANSION) return clang::CHILD_VISIT_CONTINUE;

    List{CXCursor}* cursors = (List{CXCursor}*) client;
    cursors.push(cursor);
    return clang::CHILD_VISIT_CONTINUE;
  }, (CXClientData) &cursors);

  return cursors.to_array(alloc);
}


<*
 Gets types from cursors and allocates them via alloc
*>
fn CXType[] get_types(
  Allocator alloc, 
  CXCursor[] cursors) 
  @inline
{
  CXType[] res = allocator::alloc_array(alloc, CXType, cursors.len);
  foreach (i, c : cursors) {
    switch (clang::getCursorKind(c)) {
      case clang::CURSOR_TYPEDEF_DECL:
        res[i] = clang::getTypedefDeclUnderlyingType(c);

      default:
        res[i] = clang::getCursorType(c);
    }
  }
  return res;
}


<*
 Converts an object to a string based on it's type
*>
macro String show(obj)
{
  CXString str;
  $switch $typeof(obj):
    $case CXType:
      str = clang::getTypeSpelling(obj);
    $case CXCursor:
      str = clang::getCursorSpelling(obj);
    $case CXTypeKind:
      str = clang::getTypeKindSpelling(obj);
    $default:
      return string::format(tmem, "%s", obj);
  $endswitch
  defer clang::disposeString(str);
 
  return clang::getCString(str).copy(tmem);
}


<* 
 Cleanup garbage after us
*>
fn void cleanup() @local @finalizer
{
  // Delete temp file
  Path tmp = path::temp_directory(tmem)!!;
  tmp = tmp.tappend(HEADER_NAME)!!;
  (void) path::delete(tmp);
}


ElasticArray{CXTranslationUnit, TUS_CAPACITY} translation_units @local;

