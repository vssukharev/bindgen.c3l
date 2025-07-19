
<*
 General API is as simple as it's possible. You have one only function
 'translate_header' which takes all possible information about headers
 to be translated.
*>
module bindgen::bg;
import bindgen::impl::api @public;

<*
 Main bindgen function. Translates all headers and writes result to opts.out_name. 
 WARNING: function is not tested for usage on multiple threads yet.

 @param header_name : "Header name to be translated"
 @param opts : "Options to be passed to translator"
 @param trans_callbacks : "Translation callbacks"
 @param gen_callbacks : "Values generation callbacks"

 @require gen_callbacks.if_condition == null || opts.module_name : "Can't create an unnamed module section for conditional compilation, so specify module name, please."

 @return? INVALID_ARGUMENTS, CLANG_PARSE_ERROR, CLANG_CRASH
*>
fn void? translate_header(
  String header_name, 
  BGOptions opts = {},
  BGTransCallbacks trans_callbacks = {},
  BGGenCallbacks gen_callbacks = {})
=> api::translateHeader(header_name, trans_callbacks, opts, gen_callbacks);


<* Errors *>
faultdef INVALID_ARGUMENTS, CLANG_PARSE_ERROR, CLANG_CRASH;

<*
 name "Original string from C source. Should NOT be changed"
 alloc "Allocator for the new returned string. Each allocation should be performed with that specific allocator"
 @return "Translated string, allocated via 'allocator', or empty string to skip the translation of a name (ignore it)"
*>
alias BGTransFn = fn String(String name, Allocator alloc);

<*
 name "Original string from C source. Should NOT be changed"
 alloc "Allocator for the new returned string. Each allocation should be performed with that specific allocator"
 @return "Generated value according to the name string, allocated via 'alloc'"
*>
alias BGGenFn = fn String(String name, Allocator alloc);

<*
 name : "Original string from C source. Should NOT be changed"
 @return "Boolean connected with the passed name"
*>
alias BGCheckFn = fn bool(String name);

<*
 Module wrapper function

 name : "Original string from C source. Should NOT be changed"
 @return "Module properties, with all strings of which allocated via 'alloc'"
*>
alias BGModuleWrapFn = fn BGModuleWrap(String name, Allocator alloc);

<*
 Translation callbacks is the set of functions, each of 
 which will be called when translating the corresponding 
 C entity. For instance, 'func' is invoked when we translate functions.

 func "Function"
 type "Type"
 variable "Function parameter or global variable"
 constant "Global constant"
 func_maro "Functional macro. Note: you should not prepend '@' before macro name as it will be performed automatically"
*>
struct BGTransCallbacks
{
  BGTransFn func;
  BGTransFn type;
  BGTransFn variable; 
  BGTransFn constant;
  BGTransFn func_macro;
}

<*
 Optional settings for translation.

 clang_args "Command-line args passed to clang when parsing each header. Default: no args are passed"
 out_name "Output file name into which a translation will be written. Default: result is written to stdout"
 module_name "Resulting module name, prepended at the top .c3i file. Default: no module name is written on top of .c3i"
 include_file "By default, bindgen ignore `#include` directives as C stdlib headers are usually not needed to be translated. This option is a function which returns true if we want to '#include' file passed to 'name' parameter. Note that 'name' is either relative or absolute path to a file"
 skip_errors "Whether to skip clang's parse errors. Note, that '<...> file not found' errors are skipped always and not controlled with this flag"
*>
struct BGOptions
{
  String[] clang_args;
  String out_name;
  String module_name;
  BGCheckFn include_file;
  bitstruct : char
  {
    bool skip_errors;
    bool no_verbose;
  }
}

<*
 Generation callbacks is a set of functions which will be invoked, for instance, 
 for generating problematic bodies or values for function-like 
 macros and global constants respectively

 func_macro "Functional macro body. Called for each function-like macro. Note that all functional macro parameters are translated via BGTransCallbacks.variable and prepended with '#', so you should consider when generating macro body"
 variable "Global non-const variable rhs value. Called for global variables"
 constant "Global const rhs value. Called for global constants"
 if_condition "Generates the first argument for @if conditional compilation attribute. Called for each entity"
 module_wrap "Pretty similar to the 'if_condition' function on top-level declarations like functions, structures, etc. It wraps the name into a separate module section with it's attributes (including @if conditional compilation attribute), imports and other functions. Note that using 'module_wrap' on f.e. structure fields or function parameters is impossible - in that case ues 'if_condition'. Called for each top-level declaration"
*>
struct BGGenCallbacks
{
  BGGenFn func_macro;
  BGGenFn variable;
  BGGenFn constant;
  BGGenFn if_condition;
  BGModuleWrapFn module_wrap;
}

<*
 For example `(BGModuleWrap){ .if_condition = "env::GLFW_INCLUDE_VULKAN", .imports = "vulkan; opengl" } }`
 will emit the following:
 ```
 module mname @if(env::GLFW_INCLUDE_VULKAN);
 import vulkan;
 import opengl;
 ```

 if_condition "Content of @if attribute of a generated module"
 imports "A set of imports of a generated module, separated by ';'. Note that all whitespaces after ';' till the beginning of a word are skipped"
*>
struct BGModuleWrap
{
  String if_condition;
  String imports;
}

<*
 This module is created for user comfort.
 It comprises a small set of generally necessary string
 manipulating functions, which follows the BGTransFn
 signature.
*>
module bindgen::bgstr;
import bindgen::impl::api @public;

faultdef NOT_BASIC_TYPE;

<*
 Detects wheter the given 'str' (name) is between 'a' and 'b' in declaration order.
 For example if we have something like:
 inf f1();
 int f2();
 int f3();
 bgstr::is_between("f2", "f1", "f3") will return true

 WARNING: do not use in combination with macros and some other entities
 as ALL macros are translated first so the actual order (like in header)
 is broken;
*>
fn bool is_between(String str, String a, String b) => api::strIsBetween(str, a, b);

fn String snake_to_camel(String str, Allocator alloc) => api::strSnakeToCamel(str, alloc);
fn String snake_to_pascal(String str, Allocator alloc) => api::strSnakeToPascal(str, alloc);
fn String snake_to_screaming(String str, Allocator alloc) => api::strSnakeToScreaming(str, alloc);

fn String pascal_to_screaming(String str, Allocator alloc) => api::strPascalToScreaming(str, alloc);
fn String pascal_to_snake(String str, Allocator alloc) => api::strPascalToSnake(str, alloc);
fn String pascal_to_camel(String str, Allocator alloc) => api::strPascalToCamel(str, alloc);

fn String camel_to_screaming(String str, Allocator alloc) => api::strCamelToScreaming(str, alloc);
fn String camel_to_snake(String str, Allocator alloc) => api::strCamelToSnake(str, alloc);
fn String camel_to_pascal(String str, Allocator alloc) => api::strCamelToPascal(str, alloc);

fn String screaming_to_snake(String str, Allocator alloc) => api::strScreamingToSnake(str, alloc);
fn String screaming_to_camel(String str, Allocator alloc) => api::strScreamingToCamel(str, alloc);
fn String screaming_to_pascal(String str, Allocator alloc) => api::strScreamingToPascal(str, alloc);

fn bool String.is_between(String str, String a, String b) => is_between(str, a, b);

macro String String.snake_to_camel(String str, Allocator alloc) => snake_to_camel(str, alloc);
macro String String.snake_to_pascal(String str, Allocator alloc) => snake_to_pascal(str, alloc);
macro String String.snake_to_screaming(String str, Allocator alloc) => snake_to_screaming(str, alloc);

macro String String.pascal_to_screaming(String str, Allocator alloc) => pascal_to_screaming(str, alloc);
macro String String.pascal_to_snake(String str, Allocator alloc) => pascal_to_snake(str, alloc);
macro String String.pascal_to_camel(String str, Allocator alloc) => pascal_to_camel(str, alloc);

macro String String.camel_to_screaming(String str, Allocator alloc) => camel_to_screaming(str, alloc);
macro String String.camel_to_snake(String str, Allocator alloc) => camel_to_snake(str, alloc);
macro String String.camel_to_pascal(String str, Allocator alloc) => camel_to_pascal(str, alloc);

macro String String.screaming_to_snake(String str, Allocator alloc) => screaming_to_snake(str, alloc);
macro String String.screaming_to_camel(String str, Allocator alloc) => screaming_to_camel(str, alloc);
macro String String.screaming_to_pascal(String str, Allocator alloc) => screaming_to_pascal(str, alloc);

