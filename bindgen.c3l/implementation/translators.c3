
module bindgen::impl::ttor @private;
import bindgen::impl @public;
import std::io, clang, std::collections::list;

<*
 Translates global constant declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_VAR_DECL "Cursor must point to variable declaration"
 @return "Number of bytes written"
*>
fn usz? constDecl(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String cursor_str = misc::convStr(cursor_spell);

  CXType cursor_type = clang::getCursorType(cursor);
  ConstVisitData vd_const = { .g = vd };
  
  // TODO: if we change to vd_const.val.tinit(), program terminates
  // with illegal access. I have no idea why it's happening with temporary 
  // allocator, but anyway.
  vd_const.val.init(mem);
  defer vd_const.val.free();

  // Visit rhs of var declaration and translate 
  // there everything, that is identifier
  if (clang::visitChildren(cursor, &vtor::constDecl, (CXClientData) &vd_const) != 0)
  {
    return 0;
  }
  
  String? name = trans::apply(cursor_str, vd.trans_fns.constant);

  if (catch name)
  {
    err::warn("Constant '%s' is ignored", cursor_str);
    return 0;
  }

  String? type_name = trans::ctype(cursor_type, vd.trans_fns.type, &vd.types_table);
  
  if (catch type_name)
  {
    CXString type_spell = clang::getTypeSpelling(cursor_type);
    defer clang::disposeString(type_spell);
    String type_str = misc::convStr(type_spell);

    err::warn("Can't translate constant '%s' as it's type name '%s' is ignored", cursor_str, type_str);
    return 0;
  }

  return wter::constDecl(vd.out, type_name, name, vd_const.val.str_view());
}

<*
 Translates enumDecl declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_ENUM_DECL "Cursor must point to enum declaration"
 @return "Number of bytes written"
*>
fn usz? enumDecl(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard => @pool()
{
  CXType type = clang::getCursorType(cursor);
  String? type_str = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

  if (catch type_str)
  {
    CXString type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String orig_type_str = misc::convStr(type_spell);

    err::warn("Enum '%s' is ignored", orig_type_str);
    return 0;
  }

  CXType under_type = clang::getEnumDeclIntegerType(cursor);
  String? under_type_str = trans::ctype(under_type, vd.trans_fns.type, &vd.types_table);
  
  if (catch under_type_str)
  {
    CXString type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String orig_type_str = misc::convStr(type_spell);

    CXString under_type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String orig_under_type_str = misc::convStr(type_spell);

    err::warn("Can't translate enum '%s' as it's underlying type is ignored", orig_type_str, orig_under_type_str);
    return 0;
  }

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

    if (clang::visitChildren(cursor, &vtor::enumDecl, (CXClientData) &vd_enum) != 0)
    {
      return 0;
    }

    return wter::enumDecl(vd.out, type_str, under_type_str, vd_enum.vals);
  };
}

<*
 Translates functions and writes it to 'vd.out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_FUNCTION_DECL "Cursor must point to function declaration"
 @returns "Number of bytes written"
*>
fn usz? func(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard => @pool()
{
  FuncVisitData vd_func = {
    .g = vd,
    .allocator = allocator::temp(),
  };

  vd_func.params.tinit(4);

  // Translate function parameters and store them into vd_func.params
  if (clang::visitChildren(cursor, &vtor::func, (CXClientData) &vd_func) != 0)
  {
    return 0;
  }
  
  CXString func_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(func_spell);
  String func_str = misc::convStr(func_spell);

  CXType ret_type = clang::getCursorResultType(cursor); 

  String? trans_func_str = trans::apply(func_str, vd.trans_fns.func);

  if (catch trans_func_str)
  {
    err::warn("Function '%s' is ignored", func_str);
    return 0;
  }

  String? trans_ret_type_str = trans::ctype(ret_type, vd.trans_fns.type, &vd.types_table);

  if (catch trans_ret_type_str)
  {
    CXString type_spell = clang::getTypeSpelling(ret_type);
    defer clang::disposeString(type_spell);
    String type_str = misc::convStr(type_spell);

    err::warn("Can't translate function '%s' as it's return type '%s' is ignored", func_str, type_str);
    return 0;
  }

  return wter::func(vd.out, vd_func.params.array_view(), trans_ret_type_str, func_str, trans_func_str);
}

<*
 Translates macro definition and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_MACRO_DEFINITION "Cursor must point to macro definition"
 @returns "Number of bytes written"
*>
fn usz? macroDef(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  if (clang::isMacroFunctionLike_Cursor(cursor))
  {
    return ttor::funcMacroDef(vd, cursor);
  }
  else
  {
    return ttor::constMacroDef(vd, cursor);
  }
}

<*
 Translates functional macro without generating it's body
*>
fn usz? funcMacroDef(
  GlobalVisitData* vd,
  CXCursor cursor)
{
  @pool()
  {
    CXString macro_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(macro_spell);
    String macro_str = misc::convStr(macro_spell);

    String? trans_macro_str = trans::tapply(macro_str, vd.trans_fns.func_macro);

    if (catch trans_macro_str)
    {
      err::warn("Functional macro '%s' is ignored", macro_str);
      return 0;
    }

    err::warn("Macro '%s' (@%s) is function-like so you should complete it's body manually", macro_str, trans_macro_str);

    List{String} params;
    params.tinit();

    CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
    CXSourceRange sr = misc::getTrueCursorExtent(cursor); // We don't need to do getTrueCursorExtent as bug is not occured under macro declaration
    
    CXToken* tokens_ptr; uint tokens_len;
    clang::tokenize(tu, sr, &tokens_ptr, &tokens_len);
    defer clang::disposeTokens(tu, tokens_ptr, tokens_len);

    // Make a small tweak here. TODO: get rid of it
    if OUTER: (true) 
    {
      // First token is the name of a macro and second token is left brace so start from the third one
      misc::@iterateTokens(tokens_ptr[2..tokens_len-1], tu; CXToken* token, String token_str)
      {
        if (token_str == ")") break OUTER;
        if (token_str != ",")
        {
          params.push(token_str);
        }
      };
    }

    return wter::funcMacro(vd.out, params.array_view(), trans_macro_str);
  };
}

<*
 Translates macro which is not function-like, e.g.:
 `#define MY_MACRO 1` -> `const MY_MACRO = 1;`
*>
fn usz? constMacroDef(
  GlobalVisitData* vd, 
  CXCursor cursor) 
{
  @pool()
  {
    CXString macro_spell = clang::getCursorSpelling(cursor);
    defer clang::disposeString(macro_spell);
    String macro_str = misc::convStr(macro_spell);
 
    String? trans_macro_str = trans::tapply(macro_str, vd.trans_fns.constant); 
    
    if (catch trans_macro_str)
    {
      err::warn("Constant '%s' is ignored", macro_str);
    }

    String? val = trans::tokensUnderCursor(tmem, cursor, &vd.trans_fns);
    
    if (catch val)
    {
      err::warn("Can't translate constant '%s' as it's rhs comprises ignored name", macro_str);
    }
   
    return wter::constDecl(vd.out, "", trans_macro_str, val);
  };
}

<*
 Translates structure declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_STRUCT_DECL "Cursor must point to structure declaration"
 @returns "Number of bytes written"
*>
fn usz? structDecl(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard => @pool()
{
  CXType type = clang::getCursorType(cursor);
  String? type_name = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

  if (catch type_name)
  {
    CXString type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String type_str = misc::convStr(type_spell);

    err::warn("Struct '%s' is ignored", type_str);
    return 0;
  }


  // Get fields quantity
  usz fields_len;
  clang::visitChildren(
    cursor, 
    fn CXChildVisitResult(CXCursor cursor, CXCursor parent, CXClientData client_data)
    {
      usz* fields_len = (usz*) client_data;
      ++*fields_len;
      return clang::CHILD_VISIT_CONTINUE;
    },
    (CXClientData) &fields_len
  );
  
  // If no fields are defined, type is incomplete
  if (fields_len == 0) return wter::typedefDist(vd.out, type_name, "void");

  FieldsVisitData vd_struct = {
    .g = vd,
    .allocator = allocator::temp(),
    .fields = {
      .vals = mem::temp_array(VarDecl, fields_len).ptr,
      .widths = mem::temp_array(CInt, fields_len).ptr,
      .len = fields_len,
    },
  };

  // Translate function parameters and store them into vd_struct.fields
  if (clang::visitChildren(cursor, &vtor::fields, (CXClientData) &vd_struct) != 0)
  {
    return 0;
  }

  FieldsC3? c3_fields = algo::getC3Fields(tmem, vd_struct.fields);

  if (catch c3_fields)
  {
    err::warn("Can't translate bit fields within struct '%s', skipping...", type_name);
    return 0;
  }

  return wter::structDecl(vd.out, &c3_fields, type_name);
}

<*
 Translates alias declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_TYPEDEF_DECL "Cursor must point to typedef declaration"
 @returns "Number of bytes written"
*>
fn usz? typedefDecl(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard => @pool()
{
  CXType type = clang::getCursorType(cursor);
  CXType under_type = clang::getTypedefDeclUnderlyingType(cursor);

  String? type_name = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

  if (catch type_name)
  {
    CXString type_spell = clang::getTypeSpelling(type);
    defer clang::disposeString(type_spell);
    String type_str = misc::convStr(type_spell);

    err::warn("Alias '%s' is ignored", type_str);

    return 0;
  }

  if (under_type.kind == clang::TYPE_POINTER && clang::getPointeeType(under_type).kind == clang::TYPE_FUNCTION_PROTO)
  {
    // Translate pointer to function
    FuncVisitData vd_func = {
      .g = vd,
      .allocator = allocator::temp(),
    };

    vd_func.params.tinit(4);
    
    CXType ret_type = clang::getResultType(clang::getPointeeType(under_type));
    String? ret_type_name = trans::ctype(ret_type, vd.trans_fns.type, &vd.types_table);

    if (catch ret_type_name)
    {
      CXString type_spell = clang::getTypeSpelling(ret_type);
      defer clang::disposeString(type_spell);
      String type_str = misc::convStr(type_spell);

      err::warn("Can't translate function pointer alias as it's return type '%s' is ignored", type_str);
      return 0;
    }

    // Translate function parameters and store them into vd_struct.fields
    if (clang::visitChildren(cursor, &vtor::func, (CXClientData) &vd_func) != 0)
    {
      return 0;
    }

    return wter::typedefFunc(vd.out, type_name, ret_type_name, vd_func.params.array_view());
  }
  else
  {
    // Translate alias
    String? under_type_name = trans::ctype(under_type, vd.trans_fns.type, &vd.types_table);

    if (catch under_type_name)
    {
      CXString type_spell = clang::getTypeSpelling(under_type);
      defer clang::disposeString(type_spell);
      String type_str = misc::convStr(type_spell);

      err::warn("Can't translate alias as it's underlying type '%s' is ignored", type_str);
      return 0;
    }

    return type_name != under_type_name 
      ? wter::typedefAlias(vd.out, type_name, under_type_name)
      : 0; // do not write if aliases are equal
  }
}

<*
 Union declaration and writes it to 'out'
 @require clang::getCursorKind(cursor) == clang::CURSOR_UNION_DECL "Cursor must point to union declaration"
 @returns "Number of bytes written"
*>
fn usz? unionDecl(
  GlobalVisitData* vd, 
  CXCursor cursor) 
@maydiscard
{
  @pool() {
    CXType type = clang::getCursorType(cursor);
    String? type_name = trans::ctype(type, vd.trans_fns.type, &vd.types_table);

    if (catch type_name)
    {
      CXString type_spell = clang::getTypeSpelling(type);
      defer clang::disposeString(type_spell);
      String type_str = misc::convStr(type_spell);

      err::warn("Union '%s' is ignored", type_str);
      return 0;
    }


    // Get fields quantity
    usz fields_len;
    clang::visitChildren(
      cursor, 
      fn CXChildVisitResult(CXCursor cursor, CXCursor parent, CXClientData client_data)
      {
        usz* fields_len = (usz*) client_data;
        ++*fields_len;
        return clang::CHILD_VISIT_CONTINUE;
      },
      (CXClientData) &fields_len
    );
    
    // If no fields are defined, type is incomplete
    if (fields_len == 0) return wter::typedefDist(vd.out, type_name, "void");
  
    FieldsVisitData vd_struct = {
      .g = vd,
      .allocator = allocator::temp(),
      .fields = {
        .vals = mem::temp_array(VarDecl, fields_len).ptr,
        .widths = mem::temp_array(CInt, fields_len).ptr,
        .len = fields_len,
      },
    };

    // Translate function parameters and store them into vd_struct.fields
    if (clang::visitChildren(cursor, &vtor::fields, (CXClientData) &vd_struct) != 0)
    {
      return 0;
    }

    FieldsC3? c3_fields = algo::getC3Fields(tmem, vd_struct.fields);

    if (catch c3_fields)
    {
      err::warn("Can't translate bit fields within struct '%s', skipping...", type_name);
      return 0;
    }

    return wter::unionDecl(vd.out, &c3_fields, type_name);
  };
}


