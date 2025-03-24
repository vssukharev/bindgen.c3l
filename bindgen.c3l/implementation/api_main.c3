
module bindgen::impl::api @private;
import bindgen::bg @public;
import bindgen::impl @public; 
import clang, std::collections::map, std::io, std::os::process;

const TRANSLATION_UNIT_PARSE_FLAGS =
  clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD
| clang::TRANSLATION_UNIT_IGNORE_NON_ERRORS_FROM_INCLUDED_FILES
| clang::TRANSLATION_UNIT_SKIP_FUNCTION_BODIES
// | clang::TRANSLATION_UNIT_KEEP_GOING
// | clang::TRANSLATION_UNIT_RETAIN_EXCLUDED_CONDITIONAL_BLOCKS
// | clang::TRANSLATION_UNIT_SINGLE_FILE_PARSE
;

fn void? translateHeaders(
  String[] header_file_names, 
  String output_file_name, 
  BGTransCallbacks callbacks, 
  String module_name,
  String[] command_options = {}) @inline
{
  err::log("Translating %s", header_file_names);
  err::log("Writing to %s", output_file_name);
  
  File out;
  switch (output_file_name)
  {
    case "stdout":
      out = *io::stdout();
    default:
      out = file::open(output_file_name, "w")!;
  }
  defer (void) out.close();

  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);

  if (callbacks.func == null) err::warn("Function translation will not be performed as function pointer is null");
  if (callbacks.variable == null) err::warn("Variable translation will not be performed as function pointer is null");
  if (callbacks.type == null) err::warn("Type translation will not be performed as function pointer is null");
  if (callbacks.constant == null) err::warn("Constant translation will not be performed as function pointer is null");
  if (callbacks.func_macro == null) err::warn("Functional macros translation will not be performed as function pointer is null");

  wter::moduleHead(&out, module_name);

  ZString[] cargs = user::getParseCommandArgs(tmem, command_options)!;

  foreach (header_name : header_file_names)
  {
    CXTranslationUnit tu;
    CXErrorCode code = clang::parseTranslationUnit2(index, (ZString)header_name, cargs.ptr, cargs.len, null, 0, TRANSLATION_UNIT_PARSE_FLAGS, &tu);
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

  // TODO: make freeing of command args
  // foreach (zstr : cargs)
  // {
  //   allocator::free(tmem, zstr);
  // }
}

