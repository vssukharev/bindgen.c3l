
module bindgen::user @private;
import std::os::process, std::io;
import bindgen::err @public;

const ARGS_NUM = 1;

<*
 @return "ZString[1], each element of which should be then freed"
*>
fn ZString[ARGS_NUM]! getParseCommandArgs(Allocator allocator = allocator::heap())
{
  ZString[ARGS_NUM] arr;

  // 1-st argument: libc location
  DString libc_loc;
  libc_loc.tinit();
  defer libc_loc.free();
  libc_loc.append("-I");
  user::getLibcHeadersLoc(&libc_loc, allocator)!;

  arr[0] = libc_loc.copy_zstr(allocator);

  return arr;
}

<*
 @param res 
*>
fn void! getLibcHeadersLoc(DString* res, Allocator allocator = allocator::heap())
{
  SubProcess proc = process::create({ "clang", "-E", "-Wp,-v", "-xc", "-" })!;
  proc.join()!; // join the process to close stdin of clang
  defer proc.destroy();
  File in = proc.stderr();

  bool found;
  while (!found)
  {
    if (in.read_byte()! == '\n')
    {
      char[14] buffer;
      in.read(buffer[..])!;
      if (buffer[..] == "#include <...>")
      {
        while(in.read_byte()! != '\n') {}; // read till '\n'
        found = true;
      }
    }
  }

  while (try first_c = in.read_byte() && first_c == ' ')
  {
    DString path;
    path.tinit();
    defer path.free();

    while (try c = in.read_byte() && c != '\n')
    {
      path.append(c);
    }

    usz sz = path.len();

    // Here we check for stdint.h under current directory.
    // If it's present we assume that the following path
    // contains all other headers
    path.append("/stdint.h");
    if (file::exists(path.str_view()))
    {
      res.append(path.str_view()[:sz]);
      break;
    }
  }
}

