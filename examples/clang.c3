import bindgen;
import std::ascii, std::io;

fn void main(String[] args)
{
	String out = args.len > 1 ? args[1] : "";

	BGOptions opts = {
		.out_name = out,
		.clang_args = { "-I./examples" },
		.module_name = "clang",
		.imports = { "libc" },
		.skip_errors = false,
		.generate_docs = true,
		.include_file = &include_file,
	};

	BGTransCallbacks trans_fns = {
		.type = &trans_type,
		.variable = &trans_var,
		.func = fn String(String str, Allocator alloc) =>
			str.strip("clang_").pascal_to_camel(alloc),
		.constant = &trans_const,
		.enum_field = fn String(String str, Allocator alloc) =>
			str.strip("CX").camel_to_screaming(alloc),
		.func_macro = fn String(String str, Allocator alloc) => 
			"".copy(alloc),
	};

	bg::translate_header("./examples/clang-c/clang.h", opts, trans_fns)!!;
}

fn String trans_type(String str, Allocator alloc)
{
	switch (str)
	{
		case "const char*": return "ZString".copy(alloc);
	}

	return str.copy(alloc);
}

fn String trans_var(String str, Allocator alloc) {

	switch (str)
	{
		case "Module":
		case "module": 
			return "mod".copy(alloc);
		case "fn": return "func".copy(alloc);
		default: break;
	}

	return str.camel_to_snake(alloc);
}

// seems like there is no global constant needed
fn String trans_const(String name, Allocator alloc) {
	return "".copy(alloc);
}

fn bool include_file(String name)
{
	return name.contains("clang");
}