
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
  defer proc.destroy();
  File in = proc.stderr();

  bool inside_include_section = false;
  DString current_line;
  current_line.tinit();

  while (try c = in.read_byte()) {
    if (c != '\n') {
      current_line.append(c);
      continue;
    }

    if (!inside_include_section) {
      if (current_line.str_view().contains("#include <...>")) inside_include_section = true;

    } else {
      // If we are inside the section, lines starting with ' ' are paths
      if (current_line.str_view().starts_with(" ")) {
        DString path_flag;
        path_flag.tinit();
        path_flag.append("-I");
        // Append the path, stripping the leading space
        path_flag.append(current_line.str_view()[1..]); 
        
        res.push(path_flag.copy_zstr(alloc));
      } else {
        break;
      }
    }

    current_line.clear();
  }

  proc.join()!;
}

