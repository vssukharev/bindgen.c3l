
import bindgen;

fn void main() 
{
  bg::translate_header("examples/headers/sandbox.h", {}, { .constant = &bgstr::camel_to_screaming, })!!;
}


