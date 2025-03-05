
module bindgen::bg;
import bindgen::err @public, 
       bindgen::wter @public,
       bindgen::user @public,
       bindgen::vtor @public;
import clang, std::collections::map, std::io, std::os::process;

const TRANSLATION_UNIT_PARSE_FLAGS =
  clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD
// | clang::TRANSLATION_UNIT_INCLUDE_ATTRIBUTED_TYPES
| clang::TRANSLATION_UNIT_IGNORE_NON_ERRORS_FROM_INCLUDED_FILES
| clang::TRANSLATION_UNIT_SKIP_FUNCTION_BODIES
// | clang::TRANSLATION_UNIT_KEEP_GOING
// | clang::TRANSLATION_UNIT_RETAIN_EXCLUDED_CONDITIONAL_BLOCKS
// | clang::TRANSLATION_UNIT_SINGLE_FILE_PARSE
;

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
  err::log("Translating %s", header_names);
  err::log("Writing to %s", output_name);
  
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

  if (callbacks.func == null) err::warn("Function translation will not be performed as function pointer is null");
  if (callbacks.variable == null) err::warn("Variable translation will not be performed as function pointer is null");
  if (callbacks.type == null) err::warn("Type translation will not be performed as function pointer is null");
  if (callbacks.constant == null) err::warn("Constant translation will not be performed as function pointer is null");

  wter::moduleHead(&out, module_name);

  ZString[?] cargs = user::getParseCommandArgs(tmem())!;

  foreach (header_name : header_names)
  {
    CXTranslationUnit tu;
    CXErrorCode code = clang::parseTranslationUnit2(index, (ZString)header_name, &cargs, cargs.len, null, 0, TRANSLATION_UNIT_PARSE_FLAGS, &tu);
    err::checkCode(code)!;

    CXCursor cursor = clang::getTranslationUnitCursor(tu);

    GlobalVisitData visit_data = {
      .out = &out,
      .trans_fns = callbacks,
      .cxfile = clang::getFile(tu, (ZString)header_name),
    };

    visit_data.types_table.init(mem);
    defer visit_data.types_table.free();

    clang::visitChildren(cursor, &vtor::global, (CXClientData) &visit_data);
  }

  // foreach (zstr : cargs)
  // {
  //   allocator::free(tmem(), zstr);
  // }
}

