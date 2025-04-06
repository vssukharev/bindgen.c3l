
module bindgen::impl::api @private;
import bindgen::bg @public;
import bindgen::impl @public; 
import clang, std::collections::map, std::io, std::os::process;

const TRANSLATION_UNIT_PARSE_FLAGS =
    clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD
  | clang::TRANSLATION_UNIT_IGNORE_NON_ERRORS_FROM_INCLUDED_FILES
  | clang::TRANSLATION_UNIT_SKIP_FUNCTION_BODIES
  | clang::TRANSLATION_UNIT_KEEP_GOING
  // | clang::TRANSLATION_UNIT_SINGLE_FILE_PARSE
  // The following flag cause catastrophic results. For example,
  // if we have something like `#ifdef __cplusplus` in header file,
  // who knows what code will be under this option
  // | clang::TRANSLATION_UNIT_RETAIN_EXCLUDED_CONDITIONAL_BLOCKS
;

fn void? translateHeaders(
  String[] header_file_names, 
  BGTransCallbacks trans_callbacks,
  BGOptions opts,
  BGGenCallbacks gen_callbacks)
@inline
{
  err::info("Translating %s", header_file_names);
  err::info("Writing to %s", opts.out_name);
  
  // Open file
  File out = *io::stdout();
  if (opts.out_name != "") out = file::open(opts.out_name, "w")!;
  defer (void) out.close();

  // Check callbacks
  if (trans_callbacks.func == null) err::warn("Function translation will not be performed as function pointer is null");
  if (trans_callbacks.variable == null) err::warn("Variable translation will not be performed as function pointer is null");
  if (trans_callbacks.type == null) err::warn("Type translation will not be performed as function pointer is null");
  if (trans_callbacks.constant == null) err::warn("Constant translation will not be performed as function pointer is null");
  if (trans_callbacks.func_macro == null) err::warn("Functional macros translation will not be performed as function pointer is null");

  // Write module name
  if (opts.module_name != "") wter::moduleHead(&out, opts.module_name);

  // Get command args for clang
  ZString[] cargs = user::getParseCommandArgs(tmem, opts.clang_args)!;

  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);

  foreach (header_name : header_file_names)
  {
    CXTranslationUnit tu;
    CXErrorCode code = clang::parseTranslationUnit2(index, (ZString)header_name, cargs.ptr, cargs.len, null, 0, TRANSLATION_UNIT_PARSE_FLAGS, &tu);
    err::checkCode(code)!;

    // Print diagnostics
    CUInt diagnostics_count = clang::getNumDiagnostics(tu);
    usz severe_count;
    for (CUInt i; i < diagnostics_count; ++i)
    {
      CXDiagnostic diag = clang::getDiagnostic(tu, i); 
      defer clang::disposeDiagnostic(diag);

      CXSourceLocation diag_loc = clang::getDiagnosticLocation(diag);
      CUInt line, col;
      clang::getFileLocation(diag_loc, null, &line, &col, null);

      CXString diag_spell = clang::getDiagnosticSpelling(diag);
      defer clang::disposeString(diag_spell);
      String diag_str = misc::convStr(diag_spell);

      if (clang::getDiagnosticSeverity(diag) >= clang::DIAGNOSTIC_ERROR)
      {
        // Do not count if some file is not found
        if (!diag_str.ends_with("file not found")) ++severe_count;
        err::diag(header_name, line, col, diag_str);
      }
    }

    // Return if everything is bad
    if (severe_count > 0 && !opts.skip_errors)
    {
      return bg::CLANG_PARSE_ERROR?;
    }

    GlobalVisitData visit_data = {
      .out = &out,
      .trans_fns = trans_callbacks,
      .gen_fns = gen_callbacks,
      .include_file = opts.include_file,
      .cxfile = clang::getFile(tu, (ZString)header_name),
    };

    visit_data.types_table.init(mem);
    defer visit_data.types_table.free();

    CXCursor cursor = clang::getTranslationUnitCursor(tu);
    clang::visitChildren(cursor, &vtor::global, (CXClientData) &visit_data);
  }

  // TODO: make freeing of command args
  // foreach (zstr : cargs)
  // {
  //   allocator::free(tmem, zstr);
  // }
}

