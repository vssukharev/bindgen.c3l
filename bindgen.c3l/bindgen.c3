
<*
 General API is as simple as it's possible. You have one only function
 'translate_header' which takes all possible information about headers
 to be translated.
*>
module bindgen::bg;
import bindgen::impl::api @public;

<* Errors *>
faultdef INVALID_ARGUMENTS, CLANG_PARSE_ERROR, CLANG_CRASH;

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
extern fn void? translate_header(
  String header_name, 
  BGOptions opts = {},
  BGTransCallbacks trans_callbacks = {},
  BGGenCallbacks gen_callbacks = {})
@extern("bg_translate_header");

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
 Generation callbacks is a set of functions which will be invoked, for instance, 
 for generating problematic bodies or values for function-like 
 macros and global constants respectively. 

 For instance, you have something like this:

 ```c
 #define COLOR (uint32_t) 0xFFFFFF
 ```

 In this case, there is no way for c3c to translate this constant because of '(uint32_t)' before literal.
 One thing you can do is set BGGenCallbacks.constant to the:

 ```c3
 BGGenCallbacks gens = {
   .constant = fn String(String name, Allocator alloc) => 
     name == "COLOR" ? "(uint) 0xFFFFFF" : "";
 };
 ```

 So now the output will be:

 ```c3
 const COLOR = (uint) 0xFFFFFF;
 ```
 
 Another example might be when you want to conditionally include several
 declarations:

 ```c
 struct SomeStruct {
   int a;
   #ifdef PLATFORM_1
   int b;
   #endif
 };

 #ifdef PLATFORM_2
 some_type f2();
 #endif
 ```

 In this case, 'if_condition' or 'module_wrap' might help you. 
 The first one applies `@if` attribute to a declaration, while
 the second one wraps top-level declaration into separate module
 section.

 ```c3
 BGGenCallbacks gens = {
   .if_condition = fn String(String name, Allocator alloc) => 
     name == "b" ? "PLATFORM_1" : "";
   .module_wrap = fn BGModuleWrap(String name, Allocator alloc) =>
     name == "f2" ? {
       .if_condition = "PLATFORM_2" 
     } : {};
 };
 ```

 One problem may occur here - it's missing 'some_type', which might be
 defined somewhere in the specific header file for PLATFORM_2.
 Solution for that is the section import, which you can apply to the whole
 module section. Let's modify gens:

 ```c3
 BGGenCallbacks gens = {
   .if_condition = fn String(String name, Allocator alloc) => 
     name == "b" ? "PLATFORM_1" : "";
   .module_wrap = fn BGModuleWrap(String name, Allocator alloc) =>
     name == "f2" ? {
       .if_condition = "PLATFORM_2",
       .imports = "platform_interface",
     } : {};
 };
 ```

 Also, don't forget to define PLATFORM_1 and PLATFORM_2,
 using `BGOptions.clang_args = { "-DPLATFORM_1", "-DPLATFORM_2" }`.
 So the generated code will be:
 
 ```c3
 module yourlib;

 struct SomeStruct {
   int a;
   int b @if(PLATFORM_1);
 };

 module yourlib @if(PLATFORM_2);
 import platform_interface;

 some_type f2();
 ```

 func_macro : "Functional macro body. Called for each function-like macro. Note that all functional macro parameters are translated via BGTransCallbacks.variable and prepended with '#', so you should consider this when generating macro body"

 variable : "Global non-const variable rhs value. Called for global variables"

 constant : "Global const rhs value. Called for global constants"

 if_condition : "Generates the first argument for @if conditional compilation attribute. Called for each entity"

 module_wrap : "Pretty similar to the 'if_condition' function on top-level declarations like functions, structures, etc. It wraps the name into a separate module section with it's attributes (including @if conditional compilation attribute), imports and other functions. Note that using 'module_wrap' on f.e. structure fields or function parameters is impossible - in that case use 'if_condition'. Called for each top-level declaration"
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
 name : "Original string from C source. Should NOT be changed"
 alloc : "Allocator for the new returned string. Each allocation should be performed with that specific allocator"
 @return "Translated string, allocated via 'allocator', or empty string to skip the translation of a name (ignore it)"
*>
alias BGTransFn = fn String(String name, Allocator alloc);

<*
 name : "Original string from C source. Should NOT be changed"
 alloc : "Allocator for the new returned string. Each allocation should be performed with that specific allocator"
 @return "Generated value according to the name string, allocated via 'alloc', or empty string to make no changes"
*>
alias BGGenFn = fn String(String name, Allocator alloc);

<*
 name : "Original string from C source. Should NOT be changed"
 @return "Boolean connected with the passed name"
*>
alias BGCheckFn = fn bool(String name);

<*
 name : "Original string from C source. Should NOT be changed"
 @return "Module properties, with all strings of which allocated via 'alloc'"
*>
alias BGModuleWrapFn = fn BGModuleWrap(String name, Allocator alloc);

<*
 For example `(BGModuleWrap){ .if_condition = "env::GLFW_INCLUDE_VULKAN", .imports = "vulkan; opengl" } }`
 will emit the following:

 ```c3
 module mname @if(env::GLFW_INCLUDE_VULKAN);
 import vulkan;
 import opengl;
 ```

 if_condition : "Content of @if attribute of a generated module"
 imports : "A set of imports of a generated module, separated by ';'. Note that all whitespaces after ';' till the beginning of a word are skipped"
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

fn bool is_between(String name, String bound_1, String bound_2) => api::strIsBetween(name, bound_1, bound_2);

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

fn String mixed_to_camel(String str, Allocator alloc) => api::strMixedToCamel(str, alloc);
fn String mixed_to_screaming(String str, Allocator alloc) => api::strMixedToScreaming(str, alloc);
fn String mixed_to_snake(String str, Allocator alloc) => api::strMixedToSnake(str, alloc);
fn String mixed_to_pascal(String str, Allocator alloc) => api::strMixedToPascal(str, alloc);

macro bool String.is_between(String str, String a, String b) => is_between(str, a, b);

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

