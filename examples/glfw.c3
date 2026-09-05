
import bindgen;
import std::core::ascii, std::io;


fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGOptions opts = {
    .out_name = out,
    .clang_args = { "-DGLFW_INCLUDE_VULKAN", "-I./examples/headers" },
    .module_name = "glfw",
    .skip_errors = true,
  };

  BGTransCallbacks trans_fns = {
    .func = fn String(String str, Allocator alloc) =>
      str.strip_prefix("glfw").pascal_to_camel(alloc),

    .variable = &bgstr::camel_to_snake,

    .constant = fn String(String str, Allocator alloc) =>
      str == "APIENTRY" ? "" :
      str == "GLAPIENTRY" ? "" : // ignore APIENTRY
      str.strip_prefix("GLFW_").copy(alloc),
  };

  BGGenCallbacks gen_fns = {
    .module_wrap = fn BGModuleWrap(String str, Allocator alloc) =>
      !bgstr::is_between(str, "glfwGetInstanceProcAddress", "glfwCreateWindowSurface") ? {} :
      {
        .if_condition = "GLFW_INCLUDE_VULKAN",
        .imports = "vulkan",
      },
  };

  bg::translate_header("./examples/headers/glfw3.h", opts, trans_fns, gen_fns)!!;
}


