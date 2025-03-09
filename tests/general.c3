
module cmd;
import std::io, std::os::process;

fn void log(SubProcess process)
{
  usz len = 1;
  while (len)
  {
    char[256] buffer;
    len = process.read_stderr(&buffer, buffer.len)!!;
    io::print((String) buffer[:len]);
  }
}

macro void run(String[] command)
{
  io::printfn("-------------------------------");
  SubProcess process = process::create(command, { .inherit_environment = true })!!;
  defer process.destroy();
  cmd::log(process);
}

