
module bgimpl::misc @test;
import bgtest, 
       clang, 
       std::io;


fn void test_is_type_pfn()
{
  const SUITE_TRUE = `
    typedef int (*a)();
    int b();
    int (*c)();
    typedef int (*d)(int, int);
    int e(int, int);
    int (*f)(int, int);
  `;
  
  CXCursor[] cursors = bgtest::parse(tmem, SUITE_TRUE)!!;
  CXType[] types = bgtest::get_types(tmem, cursors);
  foreach (t : types) {
    assert( isTypePFN(t) );
  }

  const SUITE_FALSE = `
    int (**a)();
    int (**b)(int, int);
    int** (*c[30])(int, int);
    int** (*d[])(int, int);
  `;

  cursors = bgtest::parse(tmem, SUITE_FALSE)!!;
  types = bgtest::get_types(tmem, cursors);
  foreach (t : types) {
    assert( !isTypePFN(t) );
  }
}


fn void test_is_cursor_forward_declared()
{
  const SUITE_TRUE = `
    struct Ss;
    union Uu;
    enum Ee;
    const int CC;
    extern int vv;
  `;

  CXCursor[] cursors = bgtest::parse(tmem, SUITE_TRUE)!!;
  foreach (c : cursors) {
    assert( isCursorForwardDeclared(c) );
  }

  const SUITE_FALSE = `
    struct Ss {};
    union Uu {};
    enum Ee { ABC };
    const int CC = 23;
    int vv = 31;
  `;

  cursors = bgtest::parse(tmem, SUITE_FALSE)!!;
  foreach (c : cursors) {
    assert( !isCursorForwardDeclared(c) );
  }
}


fn void test_is_type_incomplete()
{
  const SUITE_TRUE = `
    struct Sa* a;
    union Ua* b;
    enum Ea* c;
    int (*d)[];
  `;

  CXCursor[] cursors = bgtest::parse(tmem, SUITE_TRUE)!!;
  CXType[] types = bgtest::get_types(tmem, cursors);
  foreach (t : types) {
    CXType base = t.kind == clang::TYPE_POINTER ? clang::getPointeeType(t) : t;
    assert( isTypeIncomplete(base) );
  }

  const SUITE_FALSE = `
    struct {} a;
    union {} b;
    enum { ABC } c;
  `;

  cursors = bgtest::parse(tmem, SUITE_FALSE)!!;
  types = bgtest::get_types(tmem, cursors);
  foreach (t : types) {
    assert( !isTypeIncomplete(t) );
  }
}


fn void test_get_true_cursor_extent()
{
  const SUITE = `
    #define TEXT int
    #define TYPE TEXT*
    const TYPE a;
    TYPE f(TYPE a, TYPE b);
  `;

  const String[] EXPECT_TRUE = {
    "TEXT", "int",
    "TYPE", "TEXT", "*",
    "const", "TYPE", "a",
    "TYPE", "f", "(", "TYPE", "a", ",", "TYPE", "b", ")",
  };

  usz i;
  CXCursor[] cursors = bgtest::parse(tmem, SUITE)!!;
  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursors[0]);
  foreach (c : cursors) {
    CXToken* tokens_ptr; uint tokens_len;
    clang::tokenize(tu, getTrueCursorExtent(c), &tokens_ptr, &tokens_len);

    foreach (t : tokens_ptr[:tokens_len]) {
      CXString t_spell = clang::getTokenSpelling(tu, t);
      defer clang::disposeString(t_spell);
      String t_str = misc::convStr(t_spell);
      assert( t_str == EXPECT_TRUE[i] );
      ++i;
    }
  }
}


fn void test_get_top_children_number()
{
  const EXPECTED_1 = 3;
  const SUITE_1 = `
    struct S {
      int a;
      int b;
      int c;
    };
  `;

  const EXPECTED_2 = 4;
  const SUITE_2 = `
    struct S {
      int a;
      enum { A, B, C} e;
      int b;
    };
  `;

  // Macro expansions
  const EXPECTED_3 = 0;
  const SUITE_3 = `
    struct S {};
  `;

  CXCursor[] cursors = bgtest::parse(tmem, SUITE_1)!!;
  CXCursor parent = cursors[0];
  assert( getTopChildrenNumber(parent) == EXPECTED_1 );

  cursors = bgtest::parse(tmem, SUITE_2)!!;
  parent = cursors[0];
  assert( getTopChildrenNumber(parent) == EXPECTED_2 );

  cursors = bgtest::parse(tmem, SUITE_3)!!;
  parent = cursors[0];
  assert( getTopChildrenNumber(parent) == EXPECTED_3 );
}


fn void test_get_base_type()
{
  const SUITE_TRUE_1 = `
    int a;
    int* b;
    int c[10];
    int d[];
    int** (*e)[10];
  `;
  
  CXCursor[] cursors = bgtest::parse(tmem, SUITE_TRUE_1)!!;
  CXType[] types = bgtest::get_types(tmem, cursors);
  CXType base = types[0];
  foreach (t : types[1..]) {
    assert( base == getBaseType(t) );
  }

  const SUITE_TRUE_2 = `
    typedef int (*FnType)(int, int);
    FnType a;
    FnType* b;
    FnType c[10];
    FnType d[];
    FnType** (*e)[10];
  `;

  cursors = bgtest::parse(tmem, SUITE_TRUE_2)!!;
  types = bgtest::get_types(tmem, cursors);
  base = types[1];
  foreach (t : types[2..]) {
    assert( base == getBaseType(t) );
  }

  const SUITE_FALSE = `
    typedef int MyInt;
    int a;
    MyInt* b;
  `;

  cursors = bgtest::parse(tmem, SUITE_FALSE)!!;
  types = bgtest::get_types(tmem, cursors);
  base = types[1];
  foreach (t : types[2..]) {
    assert( base != getBaseType(t) );
  }
}


