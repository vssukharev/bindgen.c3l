
module bindgen::impl::user @private;
import bindgen::impl @public;
import std::os::process, std::io;

<*
 @param extra_opts "Additional options for clang compiler"
 @return "ZString[], which and each element of which should be then freed via allocator"
*>
fn ZString[]? getParseCommandArgs(Allocator allocator, String[] extra_opts) => @pool()
{
  const usz RESERVED_ARGS = 1;

  ZString[] arr = allocator::alloc_array(allocator, ZString, RESERVED_ARGS + extra_opts.len);

  // 1-st argument: libc location
  DString libc_loc;
  libc_loc.tinit();
  libc_loc.append("-I");
  user::getLibcHeadersLoc(&libc_loc, allocator)!;
  arr[0] = libc_loc.copy_zstr(allocator);

  // All arguments after
  if (extra_opts.len > 0)
  {
    foreach (i, &elem : arr[RESERVED_ARGS..])
    {
      *elem = (ZString) extra_opts[i];
    }
  }

  return arr;
}

<*
 @param res 
*>
fn void? getLibcHeadersLoc(DString* res, Allocator allocator = allocator::heap()) => @pool()
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

