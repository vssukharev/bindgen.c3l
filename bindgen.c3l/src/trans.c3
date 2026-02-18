
module bgimpl::trans;
import bindgen::bg, bgimpl;
import clang, std::io;


faultdef EMPTY_MACRO_VAL, NAME_IGNORED, NOT_BASIC_TYPE;


<*
 Applies function 'fun' to string 's' and allocate it via 'alloc'.
 @return? trans::NAME_IGNORED
*>
fn String? apply(
  String s, 
  BGTransFn fun, 
  Allocator alloc = mem) 
@inline 
{
  if (s.len == 0) return "";
  if (fun == null) return s.copy(alloc);

  String t = fun(s, alloc);
  if (t == "")
  {
    return trans::NAME_IGNORED~;
  }

  return t;
}


<*
 Applies 'fun' to 's', returns the new 
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
 - int[] -> CInt*
 - int[]* -> CInt* 
 - int[10] -> CInt[10]* (as function parameter)
 - int[10] -> CInt[10] (as structure field or typedef).

 @param is_func_param : "Whether this is a type of function parameter (made for arrays)"
*>
fn String? ctype(
  CXType type, 
  GlobalVisitData* vd, 
  bool is_func_param = false) 
  => @pool() 
{
  CTypeTokens tokens = tparse::getTypeTokens(tmem, type);

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
  CTypeTokenKind prev_kind = NAME;
  tokens.@foreach(;CTypeTokenKind kind, usz str_index) {
    String str = tparse::convertCTypeTokenToC3(kind, tokens.strs.array_view(), str_index);

    switch (kind) {
      case NAME:
        String trans_str = trans::basicType(str) ?? trans::capply(str, base_type, vd.trans_fns.type, &vd.types_table)!;
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
    
    ttor::pfnType(vd, res, type, cursor, { .private = true });
  } else {
    res = trans::ctype(type, vd, is_func_param)!;
  }

  return res;
}


<*
 Translates tokens under cursor.
 @return "String, allocated via alloc"
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
  if (tokens_len <= start_from) return trans::EMPTY_MACRO_VAL~;

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
        res.append(trans::literal(tmem, token_str));

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


<*
 Converts C integer or floating-point literal epressions to C3 ones
*>
fn String literal(
  Allocator alloc,
  String str)
  => @pool()
{
  // If it's a string or empty literal
  if (str.len == 0 || str[0] == '"') return str;

  bool is_float = @ok(str.index_of_char('.'));
  DString res = dstring::temp(str);

  // --- Prefixes (octal)
  if (str.len >= 2 && str[0] == '0' && str[1].is_odigit()) {
    res.insert_at(1, 'o');
  }

  // --- Suffixes
  res.replace("LL", "L");
  res.replace("ll", "l");
  
  // C3 doesn't have 'L' or 'l' literals for float so substitute them with ""
  if (is_float) {
    res.replace("L", "");
    res.replace("l", "");
  }

  return res.copy_str(alloc);
}


<*
 Maps type String to it's common representation in C3.
 If type is not mappable, throws an error.
 @return? trans::NOT_BASIC_TYPE
*>
fn String? basicType(
  String type)
{
  switch (type) {
    case "void":          return "void";
    case "_Bool":         return "bool";
    case "ptrdiff_t":     return "isz";
    case "size_t":        return "usz";

    case "char":          return "CChar";
    case "short":         return "CShort";
    case "int":           return "CInt";
    case "long":          return "CLong";
    case "long long":     return "CLongLong";

    case "unsigned char":       return "char";
    case "unsigned short":      return "CUShort";
    case "unsigned":            return "CUInt";
    case "unsigned int":        return "CUInt";
    case "unsigned long":       return "CULong";
    case "unsigned long long":  return "CULongLong";
    
    case "signed char":       return "ichar";
    case "signed short":      return "CShort";
    case "signed":            return "CUInt";
    case "signed int":        return "CInt";
    case "signed long":       return "CLong";
    case "signed long long":  return "CLongLong";

    case "int8_t":        return "ichar";
    case "int16_t":       return "short";
    case "int32_t":       return "int";
    case "int64_t":       return "long";
    case "intptr_t":      return "iptr";

    case "uint8_t":       return "char";
    case "uint16_t":      return "ushort";
    case "uint32_t":      return "uint";
    case "uint64_t":      return "ulong";
    case "uintptr_t":     return "uptr";

    case "float":         return "float";
    case "double":        return "double";

    case "va_list":       return "void*";

    default:              return NOT_BASIC_TYPE~;
  }
}

