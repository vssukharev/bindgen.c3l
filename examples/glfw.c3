
import bindgen;
import std::ascii, std::io;

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGTransCallbacks cb = {
    .func = fn String(String str, Allocator alloc) =>
      str.strip("glfw").pascal_to_camel(alloc),

    .variable = &bgstr::camel_to_snake,

    .type = fn String(String str, Allocator alloc) => 
      str.map_basic_type(alloc) ?? str.copy(alloc),

    .constant = fn String(String str, Allocator alloc) =>
      str == "APIENTRY" ? "" :
      str == "GLAPIENTRY" ? "" : // ignore APIENTRY
      str.strip("GLFW_").copy(alloc),
  };

  BGOptions opts = {
    .out_name = out,
    .clang_args = { /* "-DGLFW_INCLUDE_VULKAN", */ "-I./examples/headers" },
    .module_name = "glfw",
    // .skip_errors = true,
  };

  bg::translate_header("./examples/headers/glfw3.h", cb, opts)!!;
}


