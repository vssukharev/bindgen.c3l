
import bindgen;
import std::ascii, std::io;

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = fn String(String str, Allocator alloc) =>
      str.strip("vk").camel_to_snake(alloc),

    .type = fn String(String str, Allocator alloc) =>
      str.map_basic_type(alloc) ?? str.copy(alloc),

    .variable = fn String(String str, Allocator alloc) =>
      str == "module" ? "mod" : str.camel_to_snake(alloc),
      
    .constant = fn String(String str, Allocator alloc) =>
      str.strip("VK_").snake_to_screaming(alloc),

    .func_macro = fn String(String str, Allocator alloc) =>
      str.strip("VK_").screaming_to_snake(alloc),
  };

  bg::translate_headers({ "./examples/headers/vulkan-part.h" }, out, cb, "vulkan::vk", { "-DVK_ENABLE_BETA_EXTENSIONS" })!!;
}


