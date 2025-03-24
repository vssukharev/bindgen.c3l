
import bindgen;
import std::ascii, std::io;

fn String translateFunc(String str, Allocator alloc)
{
  return bgstr::lowerize_first(str.strip("glfw"), alloc);
}

fn String translateConstant(String str, Allocator alloc)
{
  return str.strip("GLFW_").copy(alloc);
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &translateFunc,
    .type = &bgstr::translate_type,
    .variable = &bgstr::lowerize_first,
    .constant = &translateConstant,
  };

  bg::translate_headers({"./examples/headers/glfw3.h"}, out, cb, "glfw")!!;
}


