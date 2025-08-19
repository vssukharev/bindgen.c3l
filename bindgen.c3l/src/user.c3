
module bgimpl::user;
import bgimpl,
       std::os::process, 
       std::io,
       std::collections::list;


<*
 Retrieves command args for clang and append extra_opts to it.
 @return "ZString[], which and each element of which should be then freed via alloc"
*>
fn ZString[]? getParseCommandArgs(
  Allocator alloc, 
  String[] extra_opts) 
  => @pool() 
{
  const ADD_ARGS = 4;

  List{ZString} args;
  args.init(tmem, extra_opts.len + ADD_ARGS);
 
  // Just make sure that we treat a file as a C one
  args.push("-xc");

  user::includeLibcToArgs(alloc, &args)!;

  foreach (extra_opt : extra_opts) {
    args.push((ZString)extra_opt);
  }

  return args.to_array(alloc);
}


<*
 Appends flags to res to locate libc headers for clang
 @param [&out] res 
*>
fn void? includeLibcToArgs(
  Allocator alloc,
  List{ZString}* res) 
  => @pool()
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
    res.push(path_dstr.copy_zstr(alloc));
  }
}

