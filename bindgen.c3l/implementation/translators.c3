
module bindgen::ttor @private;
import bindgen::bg @public, 
       bindgen::trans @public, 
       bindgen::vtor @public, 
       bindgen::wter @public, 
       bindgen::err @public,
       bindgen::misc @public;
import std::io, clang;

<*
 Translates global constant declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_VAR_DECL "Cursor must point to variable declaration"
 @return "Number of bytes written"
*>
fn usz! constant(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = trans::convStr(cursor_spell);

  CXType cursor_type = clang::getCursorType(cursor);

  @pool()
  {
    ConstVisitData vd_const = { .g = vd };
    vd_const.val.tinit();

    // Visit rhs of var declaration and translate 
    // there everything, that is identifier
    clang::visitChildren(cursor, &vtor::constant, (CXClientData) &vd_const);
    
    String name = trans::apply(cursor_str, vd.trans_fns.constant); 
    String type_name = trans::ctype(cursor_type, vd.trans_fns.type, &vd.types_table);

    return wter::constant(vd.out, type_name, name, vd_const.val.str_view());
  };
}

<*
 Translates enumeration declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_ENUM_DECL "Cursor must point to enum declaration"
 @returns "Number of bytes written"
*>
fn usz! enumeration(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  @pool()
  {
    CXType type = clang::getCursorType(cursor);
    String type_str = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

    CXType under_type = clang::getEnumDeclIntegerType(cursor);
    String under_type_str = trans::ctype(under_type, vd.trans_fns.type, &vd.types_table);
  
    // Get values length
    usz values_len;
    clang::visitChildren(
      cursor, 
      fn CXChildVisitResult(CXCursor cursor, CXCursor parent, CXClientData client_data)
      {
        usz* values_len = (usz*) client_data;
        ++*values_len;
        return clang::CHILD_VISIT_CONTINUE;
      },
      (CXClientData) &values_len
    );

    @pool()
    {
      EnumVisitData vd_enum = {
        .g = vd,
        .vals = {
          .names = mem::temp_array(String, values_len).ptr,
          .rhses = mem::temp_array(String, values_len).ptr,
          .len = values_len,
        }
      };

      switch (under_type.kind)
      {
        case clang::TYPE_UCHAR:
        case clang::TYPE_USHORT: 
        case clang::TYPE_UINT:      
        case clang::TYPE_ULONG:
        case clang::TYPE_ULONGLONG: 
          vd_enum.is_unsigned = true;
        default:
          vd_enum.is_unsigned = false;
      }

      clang::visitChildren(cursor, &vtor::enumeration, (CXClientData) &vd_enum);

      return wter::enumeration(vd.out, type_str, under_type_str, vd_enum.vals);
    };
  };
}

<*
 Translates functions and writes it to 'vd.out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_FUNCTION_DECL "Cursor must point to function declaration"
 @returns "Number of bytes written"
*>
fn usz! func(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  @pool() 
  {
    FuncVisitData vd_func = {
      .g = vd,
      .allocator = allocator::temp(),
    };

    vd_func.params.tinit(4);
  
    // Translate function parameters and store them into vd_func.params
    clang::visitChildren(cursor, &vtor::func, (CXClientData) &vd_func);
    
    CXString func_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(func_spell);
    String func_str = trans::convStr(func_spell);
  
    CXType ret_type = clang::getCursorResultType(cursor); 

    String trans_func_str = trans::apply(func_str, vd.trans_fns.func);
    String trans_ret_type_str = trans::ctype(ret_type, vd.trans_fns.type, &vd.types_table);

    return wter::func(vd.out, vd_func.params.array_view(), trans_ret_type_str, func_str, trans_func_str);
  };
}

<*
 Translates macro definition and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_MACRO_DEFINITION "Cursor must point to macro definition"
 @returns "Number of bytes written"
*>
fn usz! macroConst(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  CXString macro_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(macro_spell);
  String macro_str = trans::convStr(macro_spell);
  
  if (clang::isMacroFunctionLike_Cursor(cursor))
  {
    err::warn("Macro %s is function-like, skipping...", macro_str);
    return 0;
  }

  @pool()
  {
    String trans_macro_str = trans::tapply(macro_str, vd.trans_fns.constant); 

    CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
    CXSourceRange sr = clang::getCursorExtent(cursor); // We don't need to do getTrueCursorExtent as bug is not occured under macro declaration

    CXToken* tokens; uint tokens_len;
    clang::tokenize(tu, sr, &tokens, &tokens_len);
    defer clang::disposeTokens(tu, tokens, tokens_len);
    
    // If macro is empty, it's either guard or something that we might not want to translate
    if (tokens_len <= 1) 
    {
      err::warn("Macro %s doesn't have value, skipping...", macro_str);
      return 0;
    }

    DString val;
    val.tinit();
 
    misc::@iterateTokens(tokens[1..tokens_len-1], tu; String token_str, CXTokenKind token_kind)
    {
      String trans_token_str;

      switch (token_kind)
      {
        case clang::TOKEN_KEYWORD:
          err::warn("Macro %s comprises C keyword '%s', skipping...", macro_str, token_str);
          return 0;

        case clang::TOKEN_IDENTIFIER:
          trans_token_str = trans::tapply(token_str, vd.trans_fns.constant);

        case clang::TOKEN_LITERAL:
          trans_token_str = trans::tintSuf(token_str);

        default:
          trans_token_str = token_str;
      }
      
      val.append(trans_token_str);
    };

    return wter::macroConst(vd.out, trans_macro_str, val.str_view());
  };
}

<*
 Translates structure declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_STRUCT_DECL "Cursor must point to structure declaration"
 @returns "Number of bytes written"
*>
fn usz! structure(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  @pool() {
    CXType type = clang::getCursorType(cursor);
    String type_name = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

    StructVisitData vd_struct = {
      .g = vd,
      .allocator = allocator::temp(),
    };

    vd_struct.fields.tinit(4);
  
    // Translate function parameters and store them into vd_struct.fields
    clang::visitChildren(cursor, &vtor::structure, (CXClientData) &vd_struct);

    // If no fields are defined, type is incomplete
    if (vd_struct.fields.len() == 0) return wter::aliasTypedef(vd.out, type_name, "void");

    return wter::structure(vd.out, vd_struct.fields.array_view(), type_name);
  };
}

<*
 Translates alias declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_TYPEDEF_DECL "Cursor must point to typedef declaration"
 @returns "Number of bytes written"
*>
fn usz! typedef(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  CXType type = clang::getCursorType(cursor);
  CXType under_type = clang::getTypedefDeclUnderlyingType(cursor);

  @pool()
  {
    String type_name = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

    if (under_type.kind == clang::TYPE_POINTER && clang::getPointeeType(under_type).kind == clang::TYPE_FUNCTION_PROTO)
    {
      // Translate pointer to function
      FuncVisitData vd_func = {
        .g = vd,
        .allocator = allocator::temp(),
      };

      vd_func.params.tinit(4);
      
      CXType ret_type = clang::getResultType(clang::getPointeeType(under_type));
      String ret_type_name = trans::ctype(ret_type, vd.trans_fns.type, &vd.types_table);

      // Translate function parameters and store them into vd_struct.fields
      clang::visitChildren(cursor, &vtor::func, (CXClientData) &vd_func);

      return wter::funcTypedef(vd.out, type_name, ret_type_name, vd_func.params.array_view());
    }
    else
    {
      // Translate alias
      String under_type_name = trans::ctype(under_type, vd.trans_fns.type, &vd.types_table);
      
      io::fprintfn(vd.out, "// %s, %s", type_name, under_type_name);

      return type_name != under_type_name 
        ? wter::aliasTypedef(vd.out, type_name, under_type_name)
        : 0; // do not write if aliases are equal
    }
  };
}


