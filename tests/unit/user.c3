
module bgimpl::user @test;
import bgtest,
       bgimpl::misc,
       clang, 
       std::collections::list,
       std::io;


fn void test_get_parse_command_args()
{
  const SUITE_LIBC = `
    #include <stdio.h>
  `;
  
  const SUITE_MACRO = `
    const int SOME_NAME = 2;
  `;

  // Test without libc
  ZString[] args = getParseCommandArgs(tmem, no_libc: true)!!;
  if (catch exc = bgtest::parse(tmem, SUITE_LIBC, args)) {
    assert( exc == bgtest::DIAGS_FAILURE );
  }
  
  // Test with libc
  args = getParseCommandArgs(tmem, no_libc: false)!!;
  bgtest::parse(tmem, SUITE_LIBC, args, quiet: true)!!;

  // Test arguments
  args = getParseCommandArgs(tmem, { "-DSOME_NAME=hello" })!!;
  CXCursor[] cursors = bgtest::parse(tmem, SUITE_MACRO, args)!!;
  CXString spell = clang::getCursorSpelling(cursors[0]);
  defer clang::disposeString(spell);

  assert( misc::convStr(spell) == "hello" );
}


fn void test_include_libc_to_args()
{
  const SUITE = `
    #include <assert.h>
    #include <complex.h>
    #include <ctype.h>
    #include <errno.h>
    #include <fenv.h>
    #include <float.h>
    #include <inttypes.h>
    #include <limits.h>
    #include <locale.h>
    #include <math.h>
    #include <setjmp.h>
    #include <signal.h>
    #include <stdalign.h>
    #include <stdarg.h>
    #include <stdbool.h>
    #include <stddef.h>
    #include <stdint.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <tgmath.h>
    #include <time.h>
    #include <wchar.h>
    #include <wctype.h>
  `;

  List{ZString} args;
  args.tinit();
  includeLibcToArgs(tmem, &args)!!;
  bgtest::parse(tmem, SUITE, args.array_view())!!;
}


