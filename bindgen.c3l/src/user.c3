
module bgimpl::user;
import bgimpl,
       std::os::process, 
       std::io,
       std::collections::list;


<*
 Retrieves essential command args for clang and append extra_args to it.
 @return "ZString[], which and each element of which should be then freed via alloc"
*>
fn ZString[]? getParseCommandArgs(
  Allocator alloc, 
  String[] extra_args = {},
  bool no_libc = false) 
  => @pool() 
{
  const ADD_ARGS = 4;

  List{ZString} args;
  args.tinit(extra_args.len + ADD_ARGS);
  defer args.free();

  // Just make sure that we treat a file as a C one
  args.push("-xc");

  if (!no_libc) {
    user::includeLibcToArgs(alloc, &args)!;
  }

  foreach (extra_opt : extra_args) {
    args.push((ZString)extra_opt);
  }

  return args.to_array(alloc);
}


<*
 Appends flags to res to locate libc headers for clang
 @param [&out] res              : "List, which will be pushed with flags"
 @require res.is_initialized()  : "List must be initialized"
*>
fn void? includeLibcToArgs(
  Allocator alloc,
  List{ZString}* res) 
  => @pool()
{
  Process proc = process::spawn({ "clang", "-E", "-Wp,-v", "-xc", "-" })!;
  proc.join()!; // join the process to close stdin of clang
  defer proc.destroy();
  File in = proc.stderr();

  bool found;
  while (try line_check = io::treadline(&in)) {
      if (line_check.starts_with("#include <...>")) {
          found = true;
          break;
      }
  }

  while (try line = io::treadline(&in)) {
      line = line.trim();

      if (line == "End of search list.") {
          break;
      }

      if (line != "") {
          DString path;
          path.tinit();
          path.append("-I");
          path.append(line);
          res.push(path.copy_zstr(alloc));
      }
  }

}

