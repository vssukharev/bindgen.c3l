
import bindgen;

fn void main() 
{
  bg::translate_header("examples/headers/sandbox.h", {}, { .constant = &bgstr::mixed_to_screaming, })!!;
}


