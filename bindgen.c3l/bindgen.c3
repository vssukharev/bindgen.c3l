
module bindgen::bg;
import clang, std::collections::map, std::io;

const TRANSLATION_UNIT_PARSE_FLAGS =
  clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD
| clang::TRANSLATION_UNIT_INCLUDE_ATTRIBUTED_TYPES
| clang::TRANSLATION_UNIT_IGNORE_NON_ERRORS_FROM_INCLUDED_FILES
// | clang::TRANSLATION_UNIT_RETAIN_EXCLUDED_CONDITIONAL_BLOCKS
// | clang::TRANSLATION_UNIT_SINGLE_FILE_PARSE
;

<* 
 TODO: add support for custom compilation flags
 @param output_name "if stdout, write to stdout; otherwise, write to file on privided path"
*>
fn void! translateHeaders(
  String[] header_names,
  String output_name,
  BGTransCallbacks callbacks,
  String module_name)
{
  log("Translating %s", header_names);
  log("Writing to %s", output_name);
  
  File out;
  switch (output_name)
  {
    case "stdout":
      out = *io::stdout();
    default:
      out = file::open(output_name, "w")!;
  }
  defer (void) out.close();

  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);

  if (callbacks.func == null) warning("Function translation will not be performed as function pointer is null");
  if (callbacks.variable == null) warning("Variable translation will not be performed as function pointer is null");
  if (callbacks.type == null) warning("Type translation will not be performed as function pointer is null");
  if (callbacks.constant == null) warning("Constant translation will not be performed as function pointer is null");

  writeHeader(&out, module_name);

  foreach (header_name : header_names)
  {
    CXTranslationUnit tu;

    clang::parseTranslationUnit2(index, (ZString)header_name, null, 0, null, 0, TRANSLATION_UNIT_PARSE_FLAGS, &tu).check()!;
    
    CXCursor cursor = clang::getTranslationUnitCursor(tu);

    GlobalVisitData visit_data = {
      .out = &out,
      .trans_fns = callbacks,
    };

    visit_data.types_table.new_init();
    defer visit_data.types_table.free();

    clang::visitChildren(cursor, &visitorGlobal, (CXClientData) &visit_data);
  }
}

<*
 @returns "Translated string, allocated via 'allocator'"
*>
def BGTransFn = fn String (String old, Allocator allocator = allocator::heap());

struct BGTransCallbacks
{
  BGTransFn func;
  BGTransFn type;
  BGTransFn variable;
  BGTransFn constant;
}

fault BGParseError
{
  FAILURE, 
  CRASHED, 
  INVALID_ARGUMENTS,
}

