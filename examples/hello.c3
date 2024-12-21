
import bindgen;

fn void! main()
{
  BGTransCallbacks cb = {null, null, null, null};
  bg::translateHeader("./examples/dummy.h", &cb)!;
}

