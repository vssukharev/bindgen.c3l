
module bgimpl;
import bindgen::bg;
import clang, std::collections::map, std::io, std::os::process;


<*
 Implementation of bg::translate_header
*>
fn void? translateHeader(
  String header_name, 
  BGOptions opts = {},
  BGTransCallbacks trans_callbacks = {},
  BGGenCallbacks gen_callbacks = {})
  @export("bg_translate_header")
{
  err::info(opts.no_verbose, "Translating %s", header_name);
  
  // Set the output name for the user
  String out_name;

  switch {
    case (bool)opts.out_file.file:
      out_name = "file descriptor";
    case (bool)opts.out_name:
      out_name = opts.out_name;
    default:
      out_name = "standard output";
  }

  err::info(opts.no_verbose, "Writing to %s", out_name);
 
  // Open file
  File out = opts.out_file.file ? opts.out_file : *io::stdout();

  // FIX: make BGOptions.out_file override BGOptions.out_name
  if (opts.out_name != "") @pool() {
    err::warn(opts.no_verbose, "BGOptions.out_name is deprecated in favour of BGOptions.out_file");

    Path out_path = { 
      .path_string = opts.out_name,
      .env = path::DEFAULT_ENV,
    };

    if (path::is_dir(out_path)) {
      err::erro("The output name you've provided is an existing directory. Please provide a name of a file I should write to");
      return bg::INVALID_ARGUMENTS~;
    }

    // If there is no parent, we are in root
    Path out_parent = out_path.parent() ?? {
      .path_string = "/",
      .env = path::DEFAULT_ENV,
    };

    // Create missing directories on the path
    path::mkdir(out_parent, recursive: true)!!;

    out = file::open(opts.out_name, "w")!;
  };

  defer (void) out.close();

  // Check callbacks
  if (trans_callbacks.func == null) err::warn(opts.no_verbose, "Function translation will not be performed as function pointer is null");
  if (trans_callbacks.variable == null) err::warn(opts.no_verbose, "Variable translation will not be performed as function pointer is null");
  if (trans_callbacks.type == null) err::warn(opts.no_verbose, "Type translation will not be performed as function pointer is null");
  if (trans_callbacks.constant == null) err::warn(opts.no_verbose, "Constant translation will not be performed as function pointer is null");
  if (trans_callbacks.func_macro == null) err::warn(opts.no_verbose, "Functional macros translation will not be performed as function pointer is null");

  // Get command args for clang
  ZString[]? cargs = user::getParseCommandArgs(tmem, opts.clang_args);
  if (catch exc = cargs) {
    if (exc == process::FAILED_TO_START_PROCESS) {
      err::erro("Could not run 'clang' in order to find libc headers. Please, install clang");
    }
    return exc~;
  }

  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);

  if (!file::exists(header_name)) {
    err::erro("Could not find input header file '%s'. Please, check your current directory", header_name);
    return bg::INVALID_ARGUMENTS~;
  }

  CXTranslationUnit tu;
  CXErrorCode code = clang::parseTranslationUnit2(index, (ZString) header_name, cargs.ptr, cargs.len, null, 0, bgimpl::TRANSLATION_UNIT_PARSE_FLAGS, &tu);
  checkCode(code)!;
  defer clang::disposeTranslationUnit(tu);

  // Print diagnostics
  usz severe_count = runDiagnostics(tu, header_name, clang::DIAGNOSTIC_ERROR);
  if (severe_count > 0 && !opts.skip_errors) return bg::CLANG_PARSE_ERROR~;

  GlobalVisitData visit_data = {
    .trans_fns = trans_callbacks,
    .gen_fns = gen_callbacks,
    .include_file = opts.include_file,
    .module_name = opts.module_name,

    .out = &out,
    .cxfile = clang::getFile(tu, (ZString)header_name),

    .no_verbose = opts.no_verbose,
  };
  
  // TODO: also free Strings under types_table
  visit_data.types_table.init(mem);
  defer visit_data.types_table.free();

  // Write module name
  if (opts.module_name != "") wter::moduleHead(&out, &visit_data.write_state, opts.module_name);

  CXCursor cursor = clang::getTranslationUnitCursor(tu);
  clang::visitChildren(cursor, &vtor::global, (CXClientData) &visit_data);

  // TODO: make freeing of command args
  // foreach (zstr : cargs)
  // {
  //   allocator::free(tmem, zstr);
  // }
}


<*
 Run diagnostics on translation unit.
 Prints each diangostic if it is more or
 equal to the min_severity. By default, ignores 
 the file not found error, but you can override
 it by unsetting ignore_file_not_found.
 @param min_severity          : "Minimal severity for a diagnostic to be counted"
 @param ignore_file_not_found : "Whether to ignore file not found error in diagnostics"
 @return                        "Number of severe diagnostics"
*>
fn usz runDiagnostics(
  CXTranslationUnit tu,
  String header_name,
  CXDiagnosticSeverity min_severity,
  bool ignore_file_not_found = true)
  @inline
{
  CUInt diagnostics_count = clang::getNumDiagnostics(tu);
  usz severe_count;
  for (CUInt i; i < diagnostics_count; ++i) {
    CXDiagnostic diag = clang::getDiagnostic(tu, i); 
    defer clang::disposeDiagnostic(diag);

    CXSourceLocation diag_loc = clang::getDiagnosticLocation(diag);
    CUInt line, col;
    clang::getFileLocation(diag_loc, null, &line, &col, null);

    CXString diag_spell = clang::getDiagnosticSpelling(diag);
    defer clang::disposeString(diag_spell);
    String diag_str = misc::convStr(diag_spell);

    if (clang::getDiagnosticSeverity(diag) >= min_severity) {
      // Do not count if some file is not found and we don't ignore it
      if (ignore_file_not_found && diag_str.ends_with("file not found")) {
        ++severe_count;
      }
      err::diag(header_name, line, col, diag_str);
    }
  }
  return severe_count;
}


<*
 Checks clang error code and returns
 the corresponding fault if error occured
*>
fn void? checkCode(
  CXErrorCode code)
{
  switch (code) {
    case clang::ERROR_SUCCESS: 
      break;
    case clang::ERROR_FAILURE:
    case clang::ERROR_AST_READ_ERROR:
      return bg::CLANG_PARSE_ERROR~;
    case clang::ERROR_CRASHED:
      return bg::CLANG_CRASH~;
    case clang::ERROR_INVALID_ARGUMENTS:
      return bg::INVALID_ARGUMENTS~;
  }
}


const TRANSLATION_UNIT_PARSE_FLAGS =
    clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD
  | clang::TRANSLATION_UNIT_IGNORE_NON_ERRORS_FROM_INCLUDED_FILES
  | clang::TRANSLATION_UNIT_SKIP_FUNCTION_BODIES
  | clang::TRANSLATION_UNIT_KEEP_GOING;


