
module bgimpl;
import bgimpl::err;
import std::collections::list;
import std::collections::map;
import std::ascii;


alias ListString = List{String};


<*
 Implementation of bgstr::is_between
*>
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


<*
 Implementation of bgstr::snake_to_camel
*>
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


<*
 Implementation of bgstr::snake_to_screaming
*>
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


<*
 Implementation of bgstr::screaming_to_camel
*>
fn String screamingToCamel(
  String str, 
  Allocator alloc) 
  @export("bgstr_screaming_to_camel")
{
  return snakeToCamel(str, alloc) @inline;
}


<*
 Implementation of bgstr::screaming_to_pascal
*>
fn String screamingToPascal(
  String str, 
  Allocator alloc) 
  @export("bgstr_screaming_to_pascal")
{
  return snakeToPascal(str, alloc) @inline;
}


<*
 Implementation of bgstr::screaming_to_snake
*>
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


<*
 Implementation of bgstr::camel_to_snake
*>
fn String camelToSnake(
  String str, 
  Allocator alloc) 
  @export("bgstr_camel_to_snake")
  => @pool()
{
  ListString tokens = parseCamelCase(tmem, str);
  return convertToSnake(alloc, &tokens);
}


<*
 Implementation of bgstr::camel_to_screaming
*>
fn String camelToScreaming(
  String str, 
  Allocator alloc) 
  @export("bgstr_camel_to_screaming")
  => @pool() 
{
  ListString tokens = parseCamelCase(tmem, str);
  return convertToScreaming(alloc, &tokens);
}


<*
 Implementation of bgstr::camel_to_pascal
*>
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


<*
 Implementation of bgstr::pascal_to_snake
*>
fn String pascalToSnake(
  String str,
  Allocator alloc)
  @export("bgstr_pascal_to_snake")
{
  return camelToSnake(str, alloc) @inline;
}


<*
 Implementation of bgstr::pascal_to_screaming
*>
fn String pascalToScreaming(
  String str,
  Allocator alloc)
  @export("bgstr_pascal_to_screaming")
{
  return camelToScreaming(str, alloc) @inline;
}


<*
 Implementation of bgstr::pascal_to_camel
*>
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


<*
 Implementation of bgstr::mixed_to_camel
*>
fn String mixedToCamel(
  String str, 
  Allocator alloc) 
  @export("bgstr_mixed_to_camel")
  => @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToCamel(alloc, &tokens);
}


<*
 Implementation of bgstr::mixed_to_snake
*>
fn String mixedToSnake(
  String str, 
  Allocator alloc) 
  @export("bgstr_mixed_to_snake")
  => @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToSnake(alloc, &tokens);
}


<*
 Implementation of bgstr::mixed_to_screaming
*>
fn String mixedToScreaming(
  String str, 
  Allocator alloc) 
  @export("bgstr_mixed_to_screaming")
  => @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToScreaming(alloc, &tokens);  
}


<*
 Implementation of bgstr::mixed_to_pascal
*>
fn String mixedToPascal(
  String str, 
  Allocator alloc) 
  @export("bgstr_mixed_to_pascal")
  => @pool() 
{
  ListString tokens = parseMixedCase(tmem, str);
  return convertToPascal(alloc, &tokens);
}


<*
 Parses snake or screaming case to a token List.
 Snake and screaming case parsing rules:
 1. '_' at the beginning and the end of str are separate tokens
 2. All tokens are separated with one or more '_',
    regardless of the cases other characters have.
 Example: __one_two__three_ -> [ __ one two three _ ]
 @return "List, allocated via alloc"
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

  return tokens;
}


<*
 Parses camel or pascal case to a token List.
 Camel and pascal case parsing rules:
 1. '_' at the beginning and the end of str are separate tokens.
 2. First token may start with both lower or uper case characer
 3. Each subsequent token (not condidering the end one) starts
    with upper case character.
 4. If there are two or more upper case characters in a row
    and there is a following lower case character, they are treated
    as two tokens: HELLo -> [HEL Lo].
 5. Consider '_' in the middle as a regular lower case character
 6. If there are upper case characters and then digit characters in
    a row, they are treated as one token: HeLLO1 -> [He LLO1].
 7. If there is digit after lower case character or '_',
    they are treated as two separate tokens: Back_2You2 -> [Back_ 2 You 2].
 Example: __oneTwo_threeFOUR56SEVENEight9__ -> [__, one, Two_three, FOUR56, SEVEN, Eight, 9, __]
 @return "List, allocated via alloc"
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
      if (is_prev_digit) {
        tokens.push(str[begin..i-1]);
        begin = i;
      }
    }

    // If there are more than 2 capital chars or digits in a row, divide them into 2 tokens:
    // 1. first - prelast capital
    // 2. last capital - the rest
    // Example: LLVMHello -> [LLVM, Hello]
    if (i <= last && i > begin + 1) { 
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
      if (i > begin) tokens.push(str[begin..i-1]);
    }
  }

  // Push closing '_' if 'last' and 'first'
  // don't intersect
  if (last >= first && last < str.len - 1) {
    tokens.push(str[last+1..str.len-1]);
  }

  return tokens;
}


<*
 Parses mixed snake and camel case (e.g. LLVMDisassembler_ReferenceType_In_ARM64_LDRXui)
 to a token List.
 1. Parses the whole string as snake case
 2. Parses each resulted token as camel case
 @return "List of tokens, allocated via alloc"
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


<*
 Converts the list of tokens into a snake case string,
 allocated via alloc.
 1. Inserts '_' between tokens if there is no '_' before a token already
 2. Lowerizes all characters of a token
 @return "String, allocated via alloc"
*>
fn String convertToSnake(Allocator alloc, ListString* tokens) => 
  convertToSnakeOrScreaming(alloc, tokens, $to_snake: true);


<*
 Converts the list of tokens into a screaming case string,
 allocated via alloc.
 1. Inserts '_' between tokens if there is no '_' before a token already
 2. Capiitalizes all characters of a token
 @return "String, allocated via alloc"
*>
fn String convertToScreaming(Allocator alloc, ListString* tokens) =>
  convertToSnakeOrScreaming(alloc, tokens, $to_snake: false);


<*
 Converts the list of tokens into a camel case string.
 1. First token is fully lowerized
 2. All subsequent tokens have first non-'_' character upperized; 
    the rest of the characters is lowerized
 @return "String, allocated via alloc"
*>
fn String convertToCamel(Allocator alloc, ListString* tokens) => 
  convertToCamelOrPascal(alloc, tokens, $to_camel: true);


<*
 Converts the list of tokens into a pascal case string,
 allocated via alloc.
 1. Each token has first non-'_' character upperized; 
    the rest of the characters is lowerized
 @return "String, allocated via alloc"
*>
fn String convertToPascal(Allocator alloc, ListString* tokens) => 
  convertToCamelOrPascal(alloc, tokens, $to_camel: false);


<*
 Helper macro for convertToSnake and convertToScreaming. 
 - With $to_snake, has the same behaviour as convertToSnake.
 - With !$to_snake, has the same behaviour as convertToScreaming.
*>
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

  // If last token is '_', we do not insert '_' after prelast token
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


<*
 Helper macro for convertToCamel and convertToPascal.
 - With $to_camel, has the same behaviour as convertToCamel.
 - With !$to_camel, has the same behaviour as convertToPascal.
*>
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


