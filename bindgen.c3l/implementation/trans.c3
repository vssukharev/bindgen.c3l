
module bindgen::impl::trans @private;
import bindgen::bg, bindgen::impl @public;
import clang, std::io;

faultdef EMPTY, IGNORE;

<*
 Applies function 'fun' to string 's' and allocate it via 'alloc'.
 @return? IGNORE
*>
fn String? apply(
  String s, 
  BGTransFn fun, 
  Allocator alloc = allocator::heap()) 
@inline 
{
  if (s.len == 0) return "";
  if (fun == null) return s.copy(alloc);

  String t = fun(s, alloc);
  if (t == "")
  {
    return IGNORE?;
  }

  return t;
}

<*
 Applies 'fun' to 's' String, returns the new 
 translated one and caches it into types table 
 with 'key' as key type. String itself is always 
 allocated on the heap and should NOT be freed 
 as it would cause dangerous dead nodes in table.
 @param s : "String to translate"
*>
fn String? capply(
  String s, 
  CXType key,
  BGTransFn fun, 
  TypesTable* table) 
{
  String translated;

  if (try sc = (*table)[key]) {
    translated = sc;
  } else {
    translated = trans::apply(s, fun)!;
    if (table != null) (*table)[key] = translated; // 'translated' is not copied here
  }

  return translated;
}

<*
 Translates type to a string, caching it also.
 It has a special behaviour when translating a function parameter for ABI compatibility:
 int[] -> CInt*; int[]* -> CInt*; int[10] -> CInt[10]* (as function parameter); int[10] ->
 CInt[10] (as structure field or typedef).

 @param is_func_param : "Whether this is a type of function parameter (made for arrays)"
*>
fn String? ctype(
  CXType type, 
  GlobalVisitData* vd, 
  bool is_func_param = false) 
=> @pool() 
{
  TypeTokens tokens = algo::getTypeTokens(tmem, type);

  CXType base_type = misc::getBaseType(type);

  // Here we get canonical type for correct comparisons 
  // for unnamed enums or records. The main problem
  // is that clang::getCanonicalType() practically
  // erases the difference between alias and type itself,
  // so we apply it under the following conditions
  if (clang::isAnonymous_Cursor(clang::getTypeDeclaration(base_type))) {
    base_type = clang::getCanonicalType(base_type);
  }

  DString res_dstr;
  res_dstr.tinit();

  // We will never check NAME for previous kind
  TypeTokenKind prev_kind = NAME;
  tokens.@foreach(;TypeTokenKind kind, String str) {
    switch (kind) {
      case NAME:
        String trans_str = misc::mapBasicType(str) ?? trans::capply(str, base_type, vd.trans_fns.type, &vd.types_table)!;
        res_dstr.append(trans_str);

      case POINTER:
        if (prev_kind != SIZED_ARRAY || !is_func_param) res_dstr.append("*");

      case SIZED_ARRAY:
        res_dstr.append(str);
        if (is_func_param) res_dstr.append("*");

      case UNSIZED_ARRAY:
        if (prev_kind != POINTER) res_dstr.append("*");
    }

    prev_kind = kind;
  };

  return res_dstr.copy_str(mem); // TODO: get rid of leak
}

<*
 The same as trans::ctype but should be applied on types 
 which can possibly be pointers to functions. It is a superset
 of trans::ctype
*>
fn String? ctypeWithPFN(
  CXCursor cursor, 
  GlobalVisitData* vd, 
  bool is_func_param = false) 
=> @pool() 
{
  CXType type = clang::getCursorType(cursor);

  String res;
  if (misc::isTypePFN(type)) {
    if (try trans_type_str = vd.types_table[type]) return trans_type_str;

    ++vd.anon_fns_counter;
    res = string::format(mem, "UnnamedPFN%d", vd.anon_fns_counter);
    vd.types_table[type] = res;
    
    WriteAttrs attrs;
    attrs.init(tmem);
    attrs.push(PRIVATE);

    ttor::pfnType(vd, res, type, cursor, attrs);
  } else {
    res = trans::ctype(type, vd, is_func_param)!;
  }

  return res;
}

<*
 Translates tokens under cursor.
 @return "A string which then must be freed"
*>
fn String? tokensUnderCursor(
  Allocator alloc, 
  CXCursor cursor, 
  BGTransCallbacks* tfns)
=> @pool() 
{
  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = misc::convStr(cursor_spell);

  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
  CXSourceRange sr = misc::getTrueCursorExtent(cursor);

  CXToken* tokens_ptr; uint tokens_len;
  clang::tokenize(tu, sr, &tokens_ptr, &tokens_len);
  defer clang::disposeTokens(tu, tokens_ptr, tokens_len);
    
  CXCursorKind kind = clang::getCursorKind(cursor);
  
  // Token number to start iterating from. 
  // It's needed as sometimes cursor name can be also tokenized, 
  // e.g. when tokenizing a macro, first token is it's name.
  usz start_from = kind == clang::CURSOR_MACRO_DEFINITION ? 1 : 0;
  if (tokens_len <= start_from) return trans::EMPTY?;

  DString res;
  res.init(mem); // res.append() falls into infinite loop if use temp allocator
  defer res.free();
  
  bool is_in_func_macro;
  foreach (&token : tokens_ptr[start_from..tokens_len-1])
  {
    CXTokenKind token_kind = clang::getTokenKind(*token);
    CXString token_spell = clang::getTokenSpelling(tu, *token);
    defer clang::disposeString(token_spell);
    String token_str = misc::convStr(token_spell);

    if (token_str == ")") is_in_func_macro = false;

    bool is_func_macro;
    switch (token_kind) {
      // Assume that identifier is one of:
      // 1. Constant (macro)
      // 2. Functional macro
      case clang::TOKEN_IDENTIFIER:
        usz i = token - tokens_ptr;
        if (i < tokens_len - 1) {
          CXString token_spell_2 = clang::getTokenSpelling(tu, tokens_ptr[i + 1]);
          defer clang::disposeString(token_spell_2);
          String token_str_2 = misc::convStr(token_spell_2);
          if (token_str_2 == "(") {
            is_func_macro = true;
            is_in_func_macro = true;
          }
        }

        if (is_func_macro) {
          res.append("@");
          res.append(trans::apply(token_str, tfns.func_macro)!);
        } else {
          res.append(trans::apply(token_str, tfns.constant, tmem))!;
        }

      case clang::TOKEN_LITERAL:
        res.append(algo::normIntSuf(token_str, tmem));

      case clang::TOKEN_KEYWORD:
      case clang::TOKEN_PUNCTUATION:
      case clang::TOKEN_COMMENT:
        res.append(token_str);
    }
  };

  // If we finished tokenizing but we haven't encountered
  // ')' at the end, append it to result. Probably a bug of
  // a libclang that it skips ')' if macro is expanded at the
  // end of a line.
  if (is_in_func_macro) {
    res.append(")");
  }

  return res.copy_str(alloc);
}


