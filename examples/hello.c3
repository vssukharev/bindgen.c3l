
import bindgen;
import std::ascii, std::io;

fn String lowerize(String str)
{
  String str2 = str.copy();
  if (str.len == 0) return str2;
  str2[0] = str[0].to_lower();
  return str2;
}

fn String capitalize(String str)
{
  String str2 = str.copy();
  if (str.len == 0) return str2;
  str2[0] = str[0].to_upper();
  return str2;
}

fn String translateType(String str)
{
  switch (str)
  {
    case "int": return "CInt";
    case "short": return "CShort";
  }

  return capitalize(str);
}

fn String camelToSnake(String str)
{
  if (str.len == 0) return str.copy();

  @pool() {
    String buffer = (String) mem::temp_alloc_array(char, str.len + str.len / 2 + 1);

    // CaMeLcAsE -> ca_me_lc_as_e
    buffer[0] = str[0].to_lower();

    bool prev_upper = false;
    usz d = 0;
    for (usz i = 1; i < str.len; ++i)
    {
      usz a = i + d;

      buffer[a] = str[i].to_lower();

      if (str[i].is_lower()) prev_upper = false;
      if (str[i].is_upper() && !prev_upper) 
      {
        buffer[a+1] = buffer[a];
        buffer[a] = '_';
        prev_upper = true;
        ++d;
      }
    }

    return buffer[:str.len+d].copy();
  };
}

fn String translateConstant(String str, Allocator alloc = allocator::heap())
{
  return str.copy();
}


fn void! main(String[] args)
{
  String out = args.len > 1 ? args[1] : "stdout";
  
  BGTransCallbacks cb = {
    .func = &lowerize,
    .type = &translateType,
    .variable = &camelToSnake,
  };

  bg::translateHeader("./examples/dummy.h", out, cb)!;
}

