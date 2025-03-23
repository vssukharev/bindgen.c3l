
module bindgen::bg;
import bindgen::impl::api @public;

<* 
 @param header_file_names "File names of headers to be translated"
 @param output_file_name "If set to 'stdout', write to stdout; otherwise, write to file on privided path"
 @param callbacks "Translation callbacks"
 @param module_name "Name of a module appended on top of the file during translation"
 @param command_options "Command options for clang while parsing each header"
*>
fn void? translateHeaders(
  String[] header_file_names, 
  String output_file_name, 
  BGTransCallbacks callbacks, 
  String module_name,
  String[] command_options = {})
=> api::translateHeaders(header_file_names, output_file_name, callbacks, module_name, command_options) @inline;

<*
 str "Original string from C source. Should NOT be changed"
 allocator "Allocator for new returned string. Each allocation should be performed with that specific allocator"
 @return "Translated string, allocated via 'allocator'"
*>
alias BGTransFn = fn String (String str, Allocator allocator = allocator::heap());

struct BGTransCallbacks
{
  BGTransFn func; // Function
  BGTransFn type; // Type
  BGTransFn variable; // Function parameter or global variable
  BGTransFn constant; // Global constant
  BGTransFn func_macro; // Functional macro. Note: you should not prepend '@' before macro name as it will be performed automatically
}

faultdef INVALID_ARGUMENTS, CLANG_PARSE_ERROR, CLANG_CRASH;


