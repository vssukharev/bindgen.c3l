
module bgimpl::data_methods @test;
import std::io;


<*
 @require WriteAttrs.membersof.len == 2 : "Test is out of date"
*>
fn void test_WriteAttrs_to_format()
{
  DString out;
  out.tinit();
 
  const EXPECTED_1 = "";
  WriteAttrs attrs;
  io::fprint(&out, attrs)!!;
  assert( out.str_view() == EXPECTED_1 );
  out.clear();

  const EXPECTED_2 = " @if(true)";
  attrs = {
    .if_condition = "true",
  };
  io::fprint(&out, attrs)!!;
  assert( out.str_view() == EXPECTED_2 );
  out.clear();

  const EXPECTED_3 = " @private";
  attrs = {
    .private = true,
  };
  io::fprint(&out, attrs)!!;
  assert( out.str_view() == EXPECTED_3 );
  out.clear();

  const EXPECTED_4 = " @if(true) @private";
  attrs = {
    .if_condition = "true",
    .private = true,
  };
  io::fprint(&out, attrs)!!;
  assert( out.str_view() == EXPECTED_4 );
  out.clear();
}


