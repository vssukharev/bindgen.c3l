
module bindgen::bg @private;
import clang, std::io, std::collections::list;

fn CXChildVisitResult visitorFunc(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  FuncVisitData* vd = (FuncVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String translated_name = cursor_spell.toString().trans(vd.g.trans_fns.variable);

  CXString cursor_type_spell = clang::getTypeSpelling(clang::getCursorType(cursor));
  defer clang::disposeString(cursor_type_spell);
  String translated_type_name = cursor_type_spell.toString().normType().transCached(vd.g.trans_fns.type, &vd.g.types_table);

  vd.params.push({translated_type_name, translated_name});

  return clang::CHILD_VISIT_CONTINUE;
}


fn CXChildVisitResult visitorStruct(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  StructVisitData* vd = (StructVisitData*) client_data;

  CXString cursor_spell = clang::getCursorSpelling(cursor);
  defer clang::disposeString(cursor_spell);
  String original_name = cursor_spell.toString();

  CXString cursor_type_spell = clang::getTypeSpelling(clang::getCursorType(cursor));
  defer clang::disposeString(cursor_type_spell);
  String original_type_name = cursor_type_spell.toString().normType();

  String translated_name = original_name.trans(vd.g.trans_fns.variable);
  String translated_type_name = original_type_name.transCached(vd.g.trans_fns.type, &vd.g.types_table);

  vd.fields.push({translated_type_name, translated_name});

  return clang::CHILD_VISIT_CONTINUE;
}


<*
 Intended to visit rhs values of global constants, 
 translating only identifiers
*>
fn CXChildVisitResult visitorConst(
  CXCursor cursor, 
  CXCursor parent, 
  CXClientData client_data)
{
  ConstVisitData* vd = (ConstVisitData*) client_data;

  CXTranslationUnit tu = clang::getTranslationUnit_Cursor(cursor);
  CXSourceRange sr = clang::getCursorExtent(cursor);
  CXToken* tokens;
  uint tokens_len;
  
  clang::tokenize(tu, sr, &tokens, &tokens_len);
  defer clang::disposeTokens(tu, tokens, tokens_len);
  
  for (uint i; i < tokens_len; ++i)
  {
    CXString token_spell = clang::getTokenSpelling(tu, tokens[i]);
    defer clang::disposeString(token_spell);
    String token_str = token_spell.toString();
    CXTokenKind token_kind = clang::getTokenKind(tokens[i]);

    // TODO: get rid of mem leak
    String trans_token_str = token_kind == clang::TOKEN_IDENTIFIER 
      ? token_str.transCached(vd.g.trans_fns.constant, &vd.g.consts_table)
      : token_str.copy();
    
    vd.val.append(trans_token_str);

    // log("%s", token_str, indent: 1);
  }
 
  return clang::CHILD_VISIT_BREAK;
}

