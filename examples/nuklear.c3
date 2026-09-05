
import bindgen;
import std::core, std::io;

String[] defines = {
	"-DNK_INCLUDE_FIXED_TYPES",
	"-DNK_INCLUDE_STANDARD_IO",
	"-DNK_INCLUDE_DEFAULT_ALLOCATOR",
	"-DNK_INCLUDE_VERTEX_BUFFER_OUTPUT",
	"-DNK_INCLUDE_FONT_BAKING",
	"-DNK_INCLUDE_DEFAULT_FONT",
	"-DNK_INCLUDE_STANDARD_VARARGS"
};

fn void main(String[] args) 
{
	String out = args.len > 1 ? args[1] : "";

  BGOptions opts = {
		.clang_args = defines,
		.module_name = "nuklear",
		.out_name = out,
		.no_verbose = true,
  };
  bg::translate_header("examples/headers/nuklear/nuklear.h", opts, { .constant = &bgstr::camel_to_screaming, })!!;
}


