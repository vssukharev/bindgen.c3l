
import bindgen;

fn String lowerize(
  String str)
{
  if (str.len == 0) return str;
  String str2 = str.copy();
  str2[0] = str[0].to_lower();
  return str2;
}

fn void! main()
{
  BGTransCallbacks cb = {
    .function = &lowerize,
  };
  bg::translateHeader("./examples/dummy.h", &cb)!;
}


