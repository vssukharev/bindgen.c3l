module bgimpl::bgstr @test;
import bindgen::bgstr,
       std::io;


fn void test_only_underscores()
{
  assert( bgstr::snake_to_screaming("_", tmem) == "_" );
  assert( bgstr::snake_to_camel("_", tmem) == "_" );
  assert( bgstr::pascal_to_snake("_", tmem) == "_" );
  assert( bgstr::camel_to_snake("__", tmem) == "__" );
}


fn void test_single_char()
{
  assert( bgstr::snake_to_pascal("a", tmem) == "A" );
  assert( bgstr::pascal_to_snake("A", tmem) == "a" );
  assert( bgstr::pascal_to_camel("A", tmem) == "a" );
  assert( bgstr::snake_to_screaming("a", tmem) == "A" );
}


fn void test_trailing_underscore()
{
  assert( bgstr::snake_to_screaming("a_", tmem) == "A_" );
  assert( bgstr::snake_to_screaming("a_b_", tmem) == "A_B_" );
  assert( bgstr::snake_to_camel("a_b_", tmem) == "aB_" );
  assert( bgstr::snake_to_screaming("_a_b_", tmem) == "_A_B_" );
  assert( bgstr::snake_to_screaming("__ab__", tmem) == "__AB__" );
}


fn void test_capital_and_digit_runs()
{
  assert( bgstr::pascal_to_snake("LLVMHello", tmem) == "llvm_hello" );
  assert( bgstr::pascal_to_snake("ARM64MESA", tmem) == "arm64_mesa" );
  assert( bgstr::pascal_to_snake("WillBeVisible", tmem) == "will_be_visible" );
  assert( bgstr::pascal_to_camel("WillBeVisible", tmem) == "willBeVisible" );
}
