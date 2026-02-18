
import bindgen, bgimpl;
import std::io;

fn void main() 
{
  BGOptions opts = {
    .no_verbose = true,
    .module_name = "abc",
  };
  bg::translate_header("examples/headers/sandbox.h", opts, { .constant = &bgstr::camel_to_screaming, })!!;
}


