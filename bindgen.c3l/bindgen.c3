
module bindgen::bg;
import clang, std::collections::map, std::io;

// TODO: add support for custom TRANSLATION_UNIT_PARSE_FLAGS
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
fn void! translateHeader(
  String header_name,
  String output_name,
  BGTransCallbacks callbacks)
{
  log("Translating %s", header_name);
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

  CXTranslationUnit tu;

  clang::parseTranslationUnit2(
    index, 
    (ZString)header_name, 
    null, 0, null, 0, 
    TRANSLATION_UNIT_PARSE_FLAGS, &tu
  ).check()!;
  
  CXCursor cursor = clang::getTranslationUnitCursor(tu);

  GlobalVisitData visit_data = {
    .types_table = map::new(<String, String>)(),
    .out = &out,
    .trans_fns = callbacks,
  };

  defer visit_data.types_table.free();

  clang::visitChildren(cursor, &visitorGlobal, (CXClientData) &visit_data);
}

struct BGTransCallbacks
{
  BGTransFn func;
  BGTransFn type;
  BGTransFn variable;
  BGTransFn constant;
}

// All transformation functions must return to string, 
// allocated on a heap as free method will be invoked later.
def BGTransFn = fn String (String old);

// TODO: implement macro translation
// def BGMacroTransFn = fn String ();
// def BGMacroFuncTransFn = fn String ();

fault BGParseError
{
  FAILURE, 
  CRASHED, 
  INVALID_ARGUMENTS,
}

