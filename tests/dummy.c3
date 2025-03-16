
module vulkan;
import cmd;
import std::os::process, std::io;

fn void main()
{
  cmd::run({ "c3c", "run", "dummy" });
  // cmd::run({ "c3c", "compile", "-C", "build/vulkan_test.c3i" });
}

