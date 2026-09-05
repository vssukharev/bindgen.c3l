
module bgimpl::wter @test;
import std::io;

macro @reset(
  DString #out, 
  WriteState #state) 
  @local
{
  #out.clear();
  #state = {};
}


fn void test_typedef_alias()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nalias MyType = int;\n";
    
    typedefAlias(&out, &state, "MyType", "int");

    assert( state.kind == ALIAS );
    assert( out.str_view() == EXPECTED );
  }
  
  {
    defer @reset(out, state);
    const EXPECTED = "\nalias MyType @private = int;\n";

    WriteAttrs attrs = { .private = true };
    typedefAlias(&out, &state, "MyType", "int", attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_typedef_distinct()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\ntypedef MyType = int;\n";

    typedefDistinct(&out, &state, "MyType", "int");

    assert( state.kind == TYPEDEF );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\ntypedef MyType @private = int;\n";

    WriteAttrs attrs = { .private = true };
    typedefDistinct(&out, &state, "MyType", "int", attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_typedef_func()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nalias FnType = fn int();\n";

    typedefFunc(&out, &state, "FnType", "int", {});

    assert( state.kind == ALIAS );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\nalias FnType @private = fn int(\n  double,\n  float b);\n";

    VarDecl[] params = { {"double", ""}, {"float", "b"} };
    WriteAttrs attrs = { .private = true, };
    typedefFunc(&out, &state, "FnType", "int", params, attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_const_decl()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nconst int NAME = 2;\n";

    constDecl(&out, &state, "int", "NAME", "2");

    assert( state.kind == CONST );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "const int NAME @private = 0x123;\n";

    state.kind = ENUM;
    WriteAttrs attrs = { .private = true };
    constDecl(&out, &state, "int", "NAME", "0x123", attrs);

    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "const NAME @if(true) = 2.0f;\n";

    state.kind = CONST;
    WriteAttrs attrs = { .if_condition = "true" };
    constDecl(&out, &state, "", "NAME", "2.0f", attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_var_decl()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nint name = 23;\n";

    varDecl(&out, &state, "int", "name", "23");

    assert( state.kind == VAR );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\nint name @private;\n";

    state.kind = ENUM;
    WriteAttrs attrs = { .private = true };
    varDecl(&out, &state, "int", "name", "", "", attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_enum_decl()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nconstdef En : int {\n\n}\n";

    enumDecl(&out, &state, {}, "En", "int");

    assert( state.kind == ENUM );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\nconstdef En @private : int {\n\n}\n";

    WriteAttrs attrs = { .private = true };
    enumDecl(&out, &state, {}, "En", "int", "", attrs);

    assert( out.str_view() == EXPECTED );
  }
}

fn void test_func() 
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nextern fn char* f()\n@cname(\"F\");\n";

    func(&out, &state, {}, "char*", "F", "f");

    assert( state.kind == FUNC );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\nextern fn char** some_func(\n  int b,\n  double)\n@cname(\"SomeFunc\") @private;\n";

    VarDecl[] params = { {"int", "b"}, {"double", ""} };
    WriteAttrs attrs = { .private = true };
    func(&out, &state, params, "char**", "SomeFunc", "some_func", "", attrs);

    io::printfn("<%s>", out);
    assert( out.str_view() == EXPECTED );
  }
}


fn void test_func_macro()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nmacro @just_int() {}\n";

    funcMacro(&out, &state, {}, "just_int", "");

    assert( state.kind == MACRO );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\nmacro @add(#one, #two) @private {\n  return #one + #two;\n}\n";
      
    String[] params = { "one", "two" };
    WriteAttrs attrs = { .private = true };
    funcMacro(&out, &state, params, "add", "return #one + #two;", attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_module_head()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "\nmodule hello;\n";

    moduleHead(&out, &state, "hello");

    assert( state.kind == MODULE );
    assert( out.str_view() == EXPECTED );
  }

  {
    defer @reset(out, state);
    const EXPECTED = "\nmodule a @if(COND);\n";

    WriteAttrs attrs = { .if_condition = "COND" };
    moduleHead(&out, &state, "a", attrs);

    assert( out.str_view() == EXPECTED );
  }
}


fn void test_import_module()
{
  WriteState state;
  DString out;
  out.tinit();

  {
    defer @reset(out, state);
    const EXPECTED = "import m::mm;\n";

    importModule(&out, &state, "m::mm");

    assert( state.kind == IMPORT );
    assert( out.str_view() == EXPECTED );
  }
}

fn void test_struct_decl()
{
  
}

