
import bindgen;

fn void main() 
{
  bg::translate_header("examples/headers/sandbox.h", {}, { .func = &bgstr::pascal_to_snake })!!;
}


