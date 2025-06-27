
import bindgen;

fn void main() {
  String out = "build/sandbox.c3i";
  bg::translate_header("examples/headers/sandbox.h", { .out_name = out })!!;
}


