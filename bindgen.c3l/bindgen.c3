
<*
 General API is as simple as it's possible. You have one only function
 'translate_headers' which takes all possible information about headers
 to be translated.
*>
module bindgen::bg;
import bindgen::impl::api @public;

faultdef INVALID_ARGUMENTS, CLANG_PARSE_ERROR, CLANG_CRASH;


<*
 str "Original string from C source. Should NOT be changed"
 allocator "Allocator for new returned string. Each allocation should be performed with that specific allocator"
 @return "Translated string, allocated via 'allocator', or empty string to skip the translation of a name"
*>
alias BGTransFn = fn String (
  String str, 
  Allocator allocator = mem);

<*
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
 @param header_file_names "File names of headers to be translated"
 @param output_file_name "If set to 'stdout', write to stdout; otherwise, write to file under provided path"
 @param callbacks "Translation callbacks"
 @param module_name "Name of a module appended on top of the file during translation"
 @param command_options "Command options for clang while parsing each header"
 @return? INVALID_ARGUMENTS, CLANG_PARSE_ERROR, CLANG_CRASH
*>
fn void? translate_headers(
  String[] header_file_names, 
  String output_file_name, 
  BGTransCallbacks callbacks, 
  String module_name,
  String[] command_options = {})
=> api::translateHeaders(header_file_names, output_file_name, callbacks, module_name, command_options);


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
 Maps basic C type (str) to corresponding C3 ones.
 All matches:
  - some_type -> Some_type
  - void -> void (no change)
  - uint32_t -> uint
  - long long -> CLongLong
  - short -> CShort
  - char -> CChar
  - float -> float
  - double -> double
  - unsigned -> CUInt
  - unsigned int -> CUInt
  - unsigned short -> CUShort
  - unsigned char -> CUChar
  - int8_t -> ichar
  - int16_t -> short
  - int32_t -> int
  - int64_t -> long
  - uint8_t -> char
  - uint16_t -> ushort
  - uint32_t -> uint
  - uint64_t -> ulong
  - size_t -> usz
  - ptrdiff_t -> isz
  - _Bool -> bool
 NOTE: if some standard type is not written above, please look at 
 bindgen.c3l/implementation/api_utils.c3 and submit an issue on github.
 @return? NOT_BASIC_TYPE
*>
fn String? map_basic_type(String str, Allocator alloc) => api::strMapBasicType(str, alloc);

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

// Just aliases to above functions made for convenience
macro String? String.map_basic_type(String str, Allocator alloc) => map_basic_type(str, alloc);

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

