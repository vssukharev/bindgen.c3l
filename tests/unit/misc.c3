
module bgtest @test;
import bgimpl, 
       clang,
       std::io;


fn void get_base_type() => @pool()
{
  const CODE = `
  int[10]**[20] a;
  int b;
  `;

  CXCursor[] cursors = bgtest::parse(tmem, CODE);
  CXType[] types = bgtest::get_types(tmem, cursors);

  assert( misc::getBaseType(types[0]) == types[1] );
}


