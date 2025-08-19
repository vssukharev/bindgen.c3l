
module bgtest;
import bgimpl::user,
       clang,
       std::io,
       std::collections::elastic_array,
       std::collections::list;


const HEADER_NAME @local = "bgtest-parse.h";
const TUS_CAPACITY @local = 6;


<*
 Parses the code and returns cursors, pointing to top-level declarations
 @param alloc       : "Allocator, which allocates CXCursor[]"
 @param code        : "Code to be parse"
 @param extra_args  : "Arguments to clang compiler"
*>
fn CXCursor[] parse(
  Allocator alloc, 
  char[] code,
  String[] extra_args = {})
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
  ZString[] args = user::getParseCommandArgs(tmem, extra_args)!!;

  // Parse file
  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);

  CXTranslationUnit tu = clang::parseTranslationUnit(index, (ZString)tmp.str_view(), args.ptr, args.len, null, 0, PARSE_FLAGS);
  if (tu == null) abort("Could not parse translation unit");
  
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
    res[i] = clang::getCursorType(c);
  }
  return res;
}


<* 
 Cleanup garbage after us
*>
fn void cleanup() @local @finalizer
{
  // Delete temp file
  Path tmp = path::temp_directory(tmem)!!;
  tmp = tmp.tappend(HEADER_NAME)!!;
  path::delete(tmp)!!;
}


ElasticArray{CXTranslationUnit, TUS_CAPACITY} translation_units @local;

