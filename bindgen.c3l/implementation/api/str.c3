<* TODO: clean up it a bit *>
module bindgen::impl::api @private;
import bindgen::impl::err @public;
import std::collections::list;
import std::collections::map;
import std::ascii;

alias ListString = List{String};

/// ----------------- MISC -----------------

fn bool strIsBetween(String str, String a, String b) @inline {
  static HashMap{String, bool} map;
  if (!map.is_initialized()) map.init(mem);

  bool current = map[a] ?? false;

  if (str == a) {
    map[a] = true;
    current = true;
  }

  if (str == b) {
    map[a] = false;
  }

  return current;
}

/// ----------------- SNAKE CASE --------------------

fn String strSnakeToCamel(String str, Allocator alloc) @inline => @pool() {
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}

fn String strSnakeToPascal(String str, Allocator alloc) @inline => @pool() {
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}

fn String strSnakeToScreaming(String str, Allocator alloc) @inline {
  String res = str.copy(alloc);
  
  foreach (&c : res) {
    *c = c.to_upper();
  }

  return res;
}

/// ----------------- SCREAMING CASE --------------------

fn String strScreamingToCamel(String str, Allocator alloc) @inline => @pool() {
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}

fn String strScreamingToPascal(String str, Allocator alloc) @inline => @pool() {
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}

fn String strScreamingToSnake(String str, Allocator alloc) @inline {
  String res = str.copy(alloc);
  foreach (&c : res) {
    *c = c.to_lower();
  }
  return res;
}

/// ----------------- CAMEL CASE --------------------

fn String strCamelToSnake(String str, Allocator alloc) @inline => @pool() {
  ListString tokens = parseCamelCase(tmem, str);
  return convertToSnake(alloc, &tokens);
}

fn String strCamelToScreaming(String str, Allocator alloc) @inline => @pool() {
  ListString tokens = parseCamelCase(tmem, str);
  return convertToScreaming(alloc, &tokens);
}

fn String strCamelToPascal(String str, Allocator alloc) @inline {
  String res = str.copy(alloc);
  usz i;
  while (i < str.len && str[i] == '_') ++i;
  if (i < str.len) res[i] = str[i].to_upper();
  return res;
}

/// ----------------- PASCAL CASE --------------------

alias strPascalToSnake = strCamelToSnake;
alias strPascalToScreaming = strCamelToScreaming;

fn String strPascalToCamel(String str, Allocator alloc) @inline {
  String res = str.copy(alloc);
  usz i;
  while (i < str.len && str[i] == '_') ++i;
  if (i < str.len) res[i] = str[i].to_lower();
  return res;
}

/// ----------------- MIXED CASE --------------------

fn String strMixedToCamel(String str, Allocator alloc) => @pool() {
  ListString tokens = parseMixedCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}

fn String strMixedToSnake(String str, Allocator alloc) => @pool() {
  ListString tokens = parseMixedCase(tmem, str);
  return convertToSnake(alloc, &tokens);
}

fn String strMixedToScreaming(String str, Allocator alloc) => @pool() {
  ListString tokens = parseMixedCase(tmem, str);
  return convertToScreaming(alloc, &tokens);  
}

fn String strMixedToPascal(String str, Allocator alloc) => @pool() {
  ListString tokens = parseMixedCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}

/// ------------------- Local token converters -------------------

macro String convertToSnakeOrScreaming(Allocator alloc, ListString* tokens, bool $to_snake) @local {
  usz size = 0;
  foreach (t : tokens) {
    size += t.len;
    if (t[0] != '_') size += 1;
  }
  --size;

  usz last_token_index = tokens.len() - ((*tokens)[^1][0] == '_' ? 2 : 1); 

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  usz last = 0;
  foreach (i, t : tokens) {
    bool is_underscore = t[0] == '_';
    res[last:t.len] = t[..];

    foreach (&c : res[last:t.len]) {
      $if $to_snake:
        *c = c.to_lower();
      $else
        *c = c.to_upper();
      $endif
    }

    if (!is_underscore && i != last_token_index) {
      res[last+t.len] = '_';
      ++last;
    }

    last += t.len;
  }

  return res;
}

macro String convertToCamelOrPascal(Allocator alloc, ListString* tokens, bool $to_camel) @local {
  usz size = 0;
  foreach (t : tokens) {
    size += t.len;
  }

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  $if $to_camel:
    bool has_underscore = (*tokens)[0][0] == '_';
  $endif

  usz last = 0;
  foreach (i, t : *tokens) {
    res[last:t.len] = t[..];
    
    usz offset = 1;
    $if $to_camel:
      if (i == (has_underscore ? 1 : 0)) offset = 0;
    $endif

    $if $to_camel:
      if (i != (has_underscore ? 1 : 0)) {
        res[last] = res[last].to_upper();
      } else {
        res[last] = res[last].to_lower();
      }
    $else
      res[last] = res[last].to_upper();
    $endif

    for (usz j = last + offset; j < last + t.len; ++j) {
      res[j] = res[j].to_lower();
    }

    last += t.len;
  }

  return res;
}

fn String convertToSnake(Allocator alloc, ListString* tokens) @local => 
  convertToSnakeOrScreaming(alloc, tokens, $to_snake: true);

fn String convertToScreaming(Allocator alloc, ListString* tokens) @local =>
  convertToSnakeOrScreaming(alloc, tokens, $to_snake: false);

fn String convertToCamel(Allocator alloc, ListString* tokens) @local => 
  convertToCamelOrPascal(alloc, tokens, $to_camel: true);

fn String convertToPascal(Allocator alloc, ListString* tokens) @local => 
  convertToCamelOrPascal(alloc, tokens, $to_camel: false);

/// ------------------- Local parsers -------------------

<*
 Example: __one_two__three_ -> [ __ one two three _ ]
 @return "List which must be freed"
*>
fn ListString parseSnakeCase(Allocator alloc, String str) @local {
  ListString tokens;
  tokens.init(alloc, str.len / 2);

  // Treat possible beginning '_'
  usz first = 0;
  while (first < str.len && str[first] == '_') ++first;
  if (first > 0) tokens.push(str[0..first-1]);

  // Treat possible closing '_' 
  usz last = str.len - 1;
  while (last > 0 && str[last] == '_') --last;

  // Treat the rest [first..last]
  for (usz i = first; i <= last;) {
    while (i <= last && str[i] == '_') ++i;
    usz begin = i;
    while (i <= last && str[i] != '_') ++i;
    tokens.push(str[begin..i-1]);
  }

  // Push closing '_'
  if (last >= first && last < str.len - 1) {
    tokens.push(str[last+1..str.len-1]);
  }

  // err::log("Snake: %s", tokens);
  return tokens;
}

<*
 Example: __oneTWo_threeFOUR -> [ __ one TWo_three FOUR __ ]
 @return "List which then must be freed"
*>
fn ListString parseCamelCase(Allocator alloc, String str) @local {
  ListString tokens;
  tokens.init(alloc, str.len / 2);

  // Erase possible beginning '_'
  isz first = 0;
  while (first < str.len && str[first] == '_') ++first;
  if (first > 0) tokens.push(str[0..first-1]);

  // Erase possible closing '_' 
  isz last = str.len - 1;
  while (last >= 0 && str[last] == '_') --last;

  // Treat the rest [first..last]
  for (usz i = first; i <= last;) {
    usz begin = i++;

    // Handle several upper cases and digits in a row
    if (str[begin].is_upper()) {
      while (i <= last && ( str[i].is_upper() || str[i].is_digit() )) ++i;
    }

    // If there are more than 2 capital chars or digits in a row, divide them into 2 tokens:
    // 1. first - prelast capital; 2. last capital - the rest
    // Example: LLVMHello -> [LLVM, Hello]
    if (i <= last && i - begin > 1) { 
      --i;
      tokens.push(str[begin..i-1]);
      begin = i++;
    }

    while (i <= last && ( str[i] == '_' || str[i].is_lower() )) ++i;
    tokens.push(str[begin..i-1]);

    // Handle digits
    begin = i;
    while (i <= last && str[i].is_digit()) ++i;
    if (begin < i) tokens.push(str[begin..i-1]);
  }

  // Push closing '_' if 'last' and 'first'
  // don't intersect
  if (last >= first && last < str.len - 1) {
    tokens.push(str[last+1..str.len-1]);
  }

  // err::log("Camel: %s", tokens);
  return tokens;
}

<*
 Parses case like LLVMDisassembler_ReferenceType_In_ARM64_LDRXui,
 firstly parsing it as snake case and then parsing each token
 as camel case.
 @return "List which then must be freed"
*>
fn ListString parseMixedCase(Allocator alloc, String str) @local => @pool() {
  ListString tokens;
  tokens.init(alloc, str.len / 2);

  ListString snake = parseSnakeCase(tmem, str);
  foreach (s : snake) {
    ListString camel = parseCamelCase(tmem, s);
    foreach (c : camel) {
      tokens.push(c);
    }
  }

  return tokens;
}

