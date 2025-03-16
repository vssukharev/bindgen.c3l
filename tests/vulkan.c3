
module vulkan;
import cmd;
import std::os::process, std::io;

fn void main()
{
  const OUT = "build/vulkan_test.c3i";
  cmd::run({ "c3c", "run", "vulkan", "--", OUT });
  cmd::run({ "c3c", "compile", "-C", OUT });
}


