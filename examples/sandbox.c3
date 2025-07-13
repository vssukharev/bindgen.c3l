
import bindgen;

fn void main() {
  BGOptions opts = {
    // .out_name = "build/sandbox.c3i",
  };

  bg::translate_header("examples/headers/sandbox.h", opts)!!;
}


