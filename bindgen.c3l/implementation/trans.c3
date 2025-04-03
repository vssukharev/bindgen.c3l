
module bindgen::impl::trans @private;
import bindgen::bg, bindgen::impl @public;
import clang, std::io;

faultdef EMPTY, IGNORE;

fn DString* normTypeDStr(DString* ds)
{
  ds.replace("const ", "");
  ds.replace("struct ", "");
  ds.replace("enum ", "");
  ds.replace("union ", "");
  return ds;
}

fn String normTypeStr(String s, Allocator allocator = allocator::heap()) => @pool()
{
  DString dstr;
  dstr.tinit();
  dstr.append(s);
  trans::normTypeDStr(&dstr);
  return dstr.copy_str(allocator);
}

fn String? apply(String s, BGTransFn fun, Allocator alloc = allocator::heap()) @inline
{
  if (s.len == 0) return "";
  if (fun == null) return s.copy(alloc);

  String t = fun(s, alloc);
  if (t == "")
  {
    return trans::IGNORE?;
  }

  return t;
}

<*
 Applies 'fun' to 's' String, returns the new 
 translated one and caches it into translation 
 table. String itself is always allocated on the
 heap and should NOT be freed as it would cause
 dangerous dead nodes in table.
 @param s "String to translate"
 @param key "String to be used as a key in the 'table'. By default, equals to 's'"
*>
fn String? capply(
  String s, 
  BGTransFn fun, 
  TransTable* table, 
  String key = "")
{
  String translated;
  
  if (try cached = (*table)[s])
  {
    translated = cached;
  } 
  else 
  {
    translated = trans::apply(s, fun)!;

    if (key == "") key = s;
    if (table != null) (*table)[key] = translated; // 'translated' is not copied here
  }

  return translated;
}

<*
 Translates type to a string
*>
fn String? ctype(
  CXType type,
  GlobalVisitData* vd)
=> @pool()
{
  // Here we also need to recursively retrieve inner-most type,
  // like: int[]* -> int. Inner types are those we will be translating
  CXType inner_type = type;
  while LOOP: (true) 
  {
    switch (inner_type.kind)
    {
      case clang::TYPE_POINTER: 
        inner_type = clang::getPointeeType(inner_type);
      case clang::TYPE_CONSTANT_ARRAY:
      case clang::TYPE_INCOMPLETE_ARRAY:
      case clang::TYPE_COMPLEX:
      case clang::TYPE_DEPENDENT_SIZED_ARRAY:
      case clang::TYPE_VECTOR:
        inner_type = clang::getElementType(inner_type);
      default:
        break LOOP;
    }
  }

  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = misc::convStr(type_spell);

  CXString inner_type_spell = clang::getTypeSpelling(inner_type);
  defer clang::disposeString(inner_type_spell);
  String inner_type_str = trans::normTypeStr(misc::convStr(inner_type_spell), tmem);

  // Here, translation is performed under inner type and it's worth to cache also.
  // For example, if we have something like 'CXType*', 'CXType' already must be 
  // defined somewhere and, hence, cached.
  String trans_inner_type_str = trans::capply(inner_type_str, vd.trans_fns.type, &vd.types_table)!;

  // enum MyFoo -> Enum MyFoo
  DString res_dstr;
  res_dstr.tinit();
  res_dstr.append(type_str);
  trans::normTypeDStr(&res_dstr);
  res_dstr.replace(inner_type_str, trans_inner_type_str);

  String res = res_dstr.copy_str(mem);
  vd.types_table[type_str] = res;

  return res;
}

<*
 The same as trans::ctype but should be applied on types 
 which can possibly be pointers to functions. It is a superset
 of trans::ctype
*>
fn String? ctypeWithPFN(
  CXCursor cursor,
  GlobalVisitData* vd)
=> @pool()
{
  CXType type = clang::getCursorType(cursor);
  CXString type_spell = clang::getTypeSpelling(type);
  defer clang::disposeString(type_spell);
  String type_str = misc::convStr(type_spell);
  
  // Return if cached
  if (try trans_type_str = vd.types_table[type_str]) return trans_type_str;

  String res;
  if (misc::isTypePFN(type))
  {
    ++vd.anon_fns_counter;
    res = string::format(mem, "PrivateFn%s", vd.anon_fns_counter);
    vd.types_table[type_str] = res;
    
    WriteAttrs attrs;
    attrs.init(tmem);
    attrs.push(PRIVATE);

    ttor::pfnType(vd, res, type, cursor, attrs);
  }
  else
  {
    res = trans::ctype(type, vd)!;
  }

  return res;
}

<*
 The only translation is substituting 'LL' or 'll' to 'L' and 'l' respectively.
 Technically, suffix can be mixed, e.g. 'LLu', 'ull', 'llU' - only 'll'
 and 'LL' must be together and in the same case.
*>
fn String intSuf(
  String lit, 
  Allocator alloc = allocator::heap())
{
  if (lit.len == 0 || lit[0] == '"') return lit.copy(alloc);

  usz? loc = lit.index_of("LL") ?? lit.index_of("ll");
  if (catch loc) return lit.copy(alloc); // It doesn't contain LL or ll

  String new = (String) allocator::alloc_array(alloc, char, lit.len-1);

  // copy left side
  mem::copy(new.ptr, lit.ptr, loc + 1);

  // copy right side
  if (new.len - loc - 1 > 0) 
  {
    mem::copy(
      new.ptr + (loc + 1), 
      lit.ptr + (loc + 2), 
      new.len - loc - 1
    );
  }

  return new;
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
    switch (token_kind)
    {
      // Assume that identifier is one of:
      // 1. Constant (macro)
      // 2. Functional macro
      case clang::TOKEN_IDENTIFIER:
        usz i = token - tokens_ptr;
        if (i < tokens_len - 1)
        {
          CXString token_spell_2 = clang::getTokenSpelling(tu, tokens_ptr[i + 1]);
          defer clang::disposeString(token_spell_2);
          String token_str_2 = misc::convStr(token_spell_2);
          if (token_str_2 == "(") 
          {
            is_func_macro = true;
            is_in_func_macro = true;
          }
        }

        if (is_func_macro)
        {
          if (try t = trans::apply(token_str, tfns.func_macro, tmem)) 
          {
            res.append("@");
            res.append(t);
          }
        }
        else
        {
          if (try t = trans::apply(token_str, tfns.constant, tmem))
          {
            res.append(t);
          }
        }

      case clang::TOKEN_LITERAL:
        res.append(trans::intSuf(token_str, tmem));

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
  if (is_in_func_macro)
  {
    res.append(")");
  }

  return res.copy_str(alloc);
}


