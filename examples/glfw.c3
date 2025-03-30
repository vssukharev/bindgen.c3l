
import bindgen;
import std::ascii, std::io;

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
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

  bg::translate_headers({ "./examples/headers/glfw3.h" }, out, "glfw", cb, {}, { "-DVK_VERSION_1_0" })!!;
}


