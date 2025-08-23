
module bgimpl::wter @test;


fn void test_module_head()
{
  WriteState state;
  DString out;
  out.tinit();

  const EXPECTED_1 = "\nmodule hello;\n";
  moduleHead(&out, &state, "hello", {});
  assert( state.kind == MODULE );
  assert( out.str_view() == EXPECTED_1 );
  out.clear();

  const EXPECTED_2 = "\nmodule a @if(COND) @private;\n";
  WriteAttrs attrs = {
    .if_condition = "COND",
    .private = true,
  };
  moduleHead(&out, &state, "a", attrs);
  assert( out.str_view() == EXPECTED_2 );
  out.clear();
}


fn void test_import_module()
{
  WriteState state;
  DString out;
  out.tinit();

  const EXPECTED_1 = "import m::mm;\n";
  importModule(&out, &state, "m::mm");
  assert( state.kind == IMPORT );
  assert( out.str_view() == EXPECTED_1 );
  out.clear();
}

