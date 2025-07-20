
module bindgen::impl::user @private;
import bindgen::impl @public;
import std::os::process, std::io;
import std::collections::list;

<*
 @param extra_opts : "Additional options for clang compiler"
 @return "List{ZString}, which and each element of which should be then freed via allocator"
*>
fn List{ZString}? getParseCommandArgs(Allocator allocator, String[] extra_opts) => @pool() 
{
  const usz RESERVED_ARGS = 4;

  List{ZString} args;
  args.init(allocator, extra_opts.len + RESERVED_ARGS);
 
  // Just make sure that we treat a file as a C one
  args.push("-xc");

  user::getLibcHeadersLoc(&args)!;

  foreach (extra_opt : extra_opts) {
    args.push((ZString)extra_opt);
  }

  return args;
}

<*
 @param res 
*>
fn void? getLibcHeadersLoc(List{ZString}* res) => @pool()
{
  SubProcess proc = process::create({ "clang", "-E", "-Wp,-v", "-xc", "-" })!;
  proc.join()!; // join the process to close stdin of clang
  defer proc.destroy();
  File in = proc.stderr();

  bool found;
  while (!found) {
    if (in.read_byte()! == '\n') {
      char[14] buffer;
      in.read(buffer[..])!;
      if (buffer[..] == "#include <...>") {
        while(in.read_byte()! != '\n') {}; // read till '\n'
        found = true;
      }
    }
  }

  while (try first_c = in.read_byte() && first_c == ' ') {
    DString path_dstr;
    path_dstr.tinit();

    path_dstr.append("-I");
    while (try c = in.read_byte() && c != '\n') {
      path_dstr.append(c);
    }

    // Append all possible headers
    res.push(path_dstr.copy_zstr(res.allocator));
  }
}

