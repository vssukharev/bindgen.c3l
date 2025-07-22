
import bindgen;

fn void main() 
{
  bg::translate_header("examples/headers/sandbox.h", {}, { .type = &bgstr::pascal_to_snake })!!;
}


