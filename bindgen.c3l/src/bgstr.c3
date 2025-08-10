<* TODO: clean up it a bit *>
module bgimpl::bgstr;
import bgimpl::err;
import std::collections::list;
import std::collections::map;
import std::ascii;

alias ListString = List{String};

/// ----------------- MISC -----------------

fn bool isBetween(
  String str, 
  String a, 
  String b) 
@export("bgstr_is_between")
{
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

fn String snakeToCamel(
  String str, 
  Allocator alloc) 
@export("bgstr_snake_to_camel") 
=> @pool() 
{
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}

fn String snakeToPascal(
  String str, 
  Allocator alloc) 
@export("bgstr_snake_to_pascal") 
=> @pool() 
{
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}

fn String snakeToScreaming(
  String str, 
  Allocator alloc) 
@export("bgstr_snake_to_screaming") 
{
  String res = str.copy(alloc);
  foreach (&c : res) {
    *c = c.to_upper();
  }
  return res;
}

/// ----------------- SCREAMING CASE --------------------

fn String screamingToCamel(
  String str, 
  Allocator alloc) 
@export("bgstr_screaming_to_camel")
=> @pool() 
{
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}

fn String screamingToPascal(
  String str, 
  Allocator alloc) 
@export("bgstr_screaming_to_pascal")
=> @pool() 
{
  ListString tokens = parseSnakeCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}

fn String screamingToSnake(
  String str, 
  Allocator alloc) 
@export("bgstr_screaming_to_snake")
{
  String res = str.copy(alloc);
  foreach (&c : res) {
    *c = c.to_lower();
  }
  return res;
}

/// ----------------- CAMEL CASE --------------------

fn String camelToSnake(
  String str, 
  Allocator alloc) 
@export("bgstr_camel_to_snake")
=> @pool() 
{
  ListString tokens = parseCamelCase(tmem, str);
  return convertToSnake(alloc, &tokens);
}

fn String camelToScreaming(
  String str, 
  Allocator alloc) 
@export("bgstr_camel_to_screaming")
=> @pool() 
{
  ListString tokens = parseCamelCase(tmem, str);
  return convertToScreaming(alloc, &tokens);
}

fn String camelToPascal(
  String str, 
  Allocator alloc) 
@export("bgstr_camel_to_pascal")
{
  String res = str.copy(alloc);
  usz i;
  while (i < str.len && str[i] == '_') ++i;
  if (i < str.len) res[i] = str[i].to_upper();
  return res;
}

/// ----------------- PASCAL CASE --------------------

fn String pascalToSnake(
  String str,
  Allocator alloc)
@export("bgstr_pascal_to_snake")
{
  return camelToSnake(str, alloc) @inline;
}

fn String pascalToScreaming(
  String str,
  Allocator alloc)
@export("bgstr_pascal_to_screaming")
{
  return camelToScreaming(str, alloc) @inline;
}

fn String pascalToCamel(
  String str, 
  Allocator alloc) 
@export("bgstr_pascal_to_camel")
{
  String res = str.copy(alloc);
  usz i;
  while (i < str.len && str[i] == '_') ++i;
  if (i < str.len) res[i] = str[i].to_lower();
  return res;
}

/// ----------------- MIXED CASE --------------------

fn String mixedToCamel(
  String str, 
  Allocator alloc) 
@export("bgstr_mixed_to_camel")
=> @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}

fn String mixedToSnake(
  String str, 
  Allocator alloc) 
@export("bgstr_mixed_to_snake")
=> @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToSnake(alloc, &tokens);
}

fn String mixedToScreaming(
  String str, 
  Allocator alloc) 
@export("bgstr_mixed_to_screaming")
=> @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToScreaming(alloc, &tokens);  
}

fn String mixedToPascal(
  String str, 
  Allocator alloc) 
@export("bgstr_mixed_to_pascal")
=> @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}

/// ------------------- Local token converters -------------------

macro String convertToSnakeOrScreaming(
  Allocator alloc, 
  ListString* tokens, 
  bool $to_snake) 
{
  usz size = 0;
  foreach (t : tokens) {
    size += t.len;

    bool has_underscore = t[0] == '_' || t[^1] == '_';
    if (!has_underscore) size += 1;
  }
  // Substract one because of the last '_', which is not inserted
  --size;

  // If last token is '___', we do not insert '_' after prelast token
  usz last_token_index = tokens.len() - ((*tokens)[^1][0] == '_' ? 2 : 1); 

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  usz last = 0;
  foreach (i, t : tokens) {
    res[last:t.len] = t[..];

    foreach (&c : res[last:t.len]) {
      $if $to_snake:
        *c = c.to_lower();
      $else
        *c = c.to_upper();
      $endif
    }

    bool has_underscore = t[0] == '_' || t[^1] == '_';
    if (!has_underscore && i != last_token_index) {
      res[last+t.len] = '_';
      ++last;
    }

    last += t.len;
  }

  return res;
}

macro String convertToCamelOrPascal(
  Allocator alloc, 
  ListString* tokens, 
  bool $to_camel) 
{
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

fn String convertToSnake(Allocator alloc, ListString* tokens) => 
  convertToSnakeOrScreaming(alloc, tokens, $to_snake: true);

fn String convertToScreaming(Allocator alloc, ListString* tokens) =>
  convertToSnakeOrScreaming(alloc, tokens, $to_snake: false);

fn String convertToCamel(Allocator alloc, ListString* tokens) => 
  convertToCamelOrPascal(alloc, tokens, $to_camel: true);

fn String convertToPascal(Allocator alloc, ListString* tokens) => 
  convertToCamelOrPascal(alloc, tokens, $to_camel: false);

/// ------------------- Local parsers -------------------

<*
 Example: __one_two__three_ -> [ __ one two three _ ]
 @return "List which must be freed"
*>
fn ListString parseSnakeCase(
  Allocator alloc, 
  String str) 
{
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
 Example: __oneTWo_threeFOUR__ -> [ __ one T Wo_three FOUR __ ]
 @return "List which then must be freed"
*>
fn ListString parseCamelCase(
  Allocator alloc, 
  String str) 
{
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
    bool is_prev_digit = false;
    if (str[begin].is_upper()) {
      while (i <= last && str[i].is_upper()) ++i;
      while (i <= last && ( str[i].is_digit() || str[i] == '_' )) {
        is_prev_digit = true;
        ++i;
      }
    }

    // If there are more than 2 capital chars or digits in a row, divide them into 2 tokens:
    // 1. first - prelast capital; 2. last capital - the rest
    // Example: LLVMHello -> [LLVM, Hello]
    if (i <= last && i - begin > 1) { 
      if (!is_prev_digit) --i;
      tokens.push(str[begin..i-1]);
      begin = i;
    }

    // If previous char is a digit or an underscore, go to the next iteration
    // as upper case and digits might follow it, like in ARM64MESA
    if (!is_prev_digit) {
      // Handle lower case
      while (i <= last && ( str[i].is_lower() || str[i] == '_' )) ++i;
      if (i > begin) tokens.push(str[begin..i-1]);

      // Handle digits
      begin = i;
      while (i <= last && str[i].is_digit()) ++i;
      if (begin < i) tokens.push(str[begin..i-1]);
    }
  }

  // Push closing '_' if 'last' and 'first'
  // don't intersect
  if (last >= first && last < str.len - 1) {
    tokens.push(str[last+1..str.len-1]);
  }

  // err::log("%s", tokens);
  return tokens;
}

<*
 Parses case like LLVMDisassembler_ReferenceType_In_ARM64_LDRXui,
 firstly parsing it as snake case and then parsing each token
 as camel case.
 @return "List which then must be freed"
*>
fn ListString parseMixedCase(
  Allocator alloc, 
  String str) 
=> @pool() 
{
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

