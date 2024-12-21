
module bindgen::bg @public;
import clang;

fault BGParseError
{
  FAILURE, 
  CRASHED, 
  INVALID_ARGUMENTS,
}

def BGFuncTransFn = fn String ();
def BGTypeTransFn = fn String ();
def BGVarTransFn = fn String ();
def BGConstTransFn = fn String ();

struct BGTransCallbacks
{
  BGFuncTransFn function;
  BGTypeTransFn type;
  BGVarTransFn variable;
  BGConstTransFn constant;
}

// TODO: implement macro translation
// def BGMacroTransFn = fn BGEntity ();
// def BGMacroFuncTransFn = fn BGEntity ();

// TODO: add support for custom TRANSLATION_UNIT_PARSE_FLAGS
const TRANSLATION_UNIT_PARSE_FLAGS =
  clang::TRANSLATION_UNIT_DETAILED_PREPROCESSING_RECORD
| clang::TRANSLATION_UNIT_INCLUDE_ATTRIBUTED_TYPES
| clang::TRANSLATION_UNIT_IGNORE_NON_ERRORS_FROM_INCLUDED_FILES
// | clang::TRANSLATION_UNIT_RETAIN_EXCLUDED_CONDITIONAL_BLOCKS
// | clang::TRANSLATION_UNIT_SINGLE_FILE_PARSE
;

// TODO: add support for custom compilation flags
fn void! translateHeader(
  String header_name,
  BGTransCallbacks* callbacks)
{
  log("Translate %s", header_name);
  CXIndex index = clang::createIndex(0, 0);
  defer clang::disposeIndex(index);

  CXTranslationUnit tu;
  processErrCode(
    clang::parseTranslationUnit2(
      index, 
      (ZString)header_name, 
      null, 0, null, 0, 
      TRANSLATION_UNIT_PARSE_FLAGS, &tu
    )
  )!;
  
  CXCursor cursor = clang::getTranslationUnitCursor(tu);
  VisitDataGlobal visit_data = {callbacks};
  clang::visitChildren(cursor, &visitorGlobal, (CXClientData) &visit_data);
}
