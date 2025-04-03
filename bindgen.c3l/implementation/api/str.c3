<* TODO: clean up it a bit *>
module bindgen::impl::api @private;
import bindgen::impl @public;
import bindgen::bgstr;
import std::collections::list, std::ascii;
import std::collections::map;

alias ListString = List{String};

fn String strLowerizeFirst(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_lower();
  return str2;
}

fn String strLowerizeAll(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  foreach (i, &c : str2)
  {
    *c = str[i].to_lower();
  }
  return str2;
}

fn String strCapitalizeFirst(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  str2[0] = str[0].to_upper();
  return str2;
}

fn String strCapitalizeAll(String str, Allocator alloc) @inline
{
  String str2 = str.copy(alloc);
  if (str.len == 0) return str2;
  for (usz i; i < str.len; ++i) {
    str2[i] = str[i].to_upper();
  }
  return str2;
}

fn String? strMapBasicType(String str, Allocator alloc) @inline
{
  switch (str)
  {
    case "void":          return "void".copy(alloc);
    case "_Bool":         return "bool".copy(alloc);
    case "ptrdiff_t":     return "isz".copy(alloc);
    case "size_t":        return "usz".copy(alloc);

    case "char":          return "CChar".copy(alloc);
    case "short":         return "CShort".copy(alloc);
    case "int":           return "CInt".copy(alloc);
    case "long":          return "CLong".copy(alloc);
    case "long long":     return "CLongLong".copy(alloc);

    case "unsigned char":       return "char".copy(alloc);
    case "unsigned short":      return "CUShort".copy(alloc);
    case "unsigned":            return "CUInt".copy(alloc);
    case "unsigned int":        return "CUInt".copy(alloc);
    case "unsigned long":       return "CULong".copy(alloc);
    case "unsigned long long":  return "CULongLong".copy(alloc);
    
    case "signed char":       return "ichar".copy(alloc);
    case "signed short":      return "CShort".copy(alloc);
    case "signed":            return "CUInt".copy(alloc);
    case "signed int":        return "CInt".copy(alloc);
    case "signed long":       return "CLong".copy(alloc);
    case "signed long long":  return "CLongLong".copy(alloc);

    case "int8_t":        return "ichar".copy(alloc);
    case "int16_t":       return "short".copy(alloc);
    case "int32_t":       return "int".copy(alloc);
    case "int64_t":       return "long".copy(alloc);
    case "intptr_t":      return "iptr".copy(alloc);

    case "uint8_t":       return "char".copy(alloc);
    case "uint16_t":      return "ushort".copy(alloc);
    case "uint32_t":      return "uint".copy(alloc);
    case "uint64_t":      return "ulong".copy(alloc);
    case "uintptr_t":     return "uptr".copy(alloc);

    case "float":         return "float".copy(alloc);
    case "double":        return "double".copy(alloc);

    case "va_list":       return "void*".copy(alloc);

    default:              return bgstr::NOT_BASIC_TYPE?;
  }
}

fn bool strIsBetween(String str, String a, String b) @inline
{
  static HashMap{String, bool} map;
  if (!map.is_initialized()) map.init(mem);

  bool current = map[a] ?? false;

  if (str == a)
  {
    map[a] = true;
    current = true;
  }

  if (str == b)
  {
    map[a] = false;
  }

  return current;
}


/// ----------------- SNAKE CASE --------------------

fn String strSnakeToCamel(String str, Allocator alloc) @inline => @pool()
{
  ListString tokens = parseSnakeCase(tmem, str);
  
  usz size = 0;
  foreach (t : tokens)
  {
    size += t.len;
  }

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  bool has_underscore = tokens[0][0] == '_';

  usz last = 0;
  foreach (i, t : tokens)
  {
    res[last:t.len] = t;

    if (i != (has_underscore ? 1 : 0))
    {
      res[last] = res[last].to_upper();
    }
    else
    {
      res[last] = res[last].to_lower();
    }

    last += t.len;
  }

  return res;
}

fn String strSnakeToPascal(String str, Allocator alloc) @inline => @pool()
{
  ListString tokens = parseSnakeCase(tmem, str);
  
  usz size = 0;
  foreach (t : tokens)
  {
    size += t.len;
  }

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  usz last = 0;
  foreach (i, t : tokens)
  {
    res[last:t.len] = t;
    res[last] = res[last].to_upper();
    last += t.len;
  }

  return res;
}

fn String strSnakeToScreaming(String str, Allocator alloc) @inline
{
  String res = str.copy(alloc);
  
  foreach (&c : res)
  {
    *c = c.to_upper();
  }

  return res;
}

/// ----------------- SCREAMING CASE --------------------

fn String strScreamingToCamel(String str, Allocator alloc) @inline => @pool()
{
  ListString tokens = parseSnakeCase(tmem, str);
  
  usz size = 0;
  foreach (t : tokens)
  {
    size += t.len;
  }

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  bool has_underscore = tokens[0][0] == '_';

  usz last = 0;
  foreach (i, t : tokens)
  {
    res[last:t.len] = t;
    
    usz offset = 1;
    if (i == (has_underscore ? 1 : 0)) offset = 0;

    for (usz j = last + offset; j < last + t.len; ++j)
    {
      res[j] = res[j].to_lower();
    }

    last += t.len;
  }

  return res;
}

fn String strScreamingToPascal(String str, Allocator alloc) @inline => @pool()
{
  ListString tokens = parseSnakeCase(tmem, str);
  
  usz size = 0;
  foreach (t : tokens)
  {
    size += t.len;
  }

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  usz last = 0;
  foreach (i, t : tokens)
  {
    res[last:t.len] = t;
    
    for (usz j = last + 1; j < last + t.len; ++j)
    {
      res[j] = res[j].to_lower();
    }

    last += t.len;
  }

  return res;
}

fn String strScreamingToSnake(String str, Allocator alloc) @inline
{
  String res = str.copy(alloc);
  
  foreach (&c : res)
  {
    *c = c.to_lower();
  }

  return res;
}


/// ----------------- CAMEL CASE --------------------

fn String strCamelToSnake(String str, Allocator alloc) @inline => @pool()
{
  ListString tokens = parseCamelCase(tmem, str);
  
  usz size = 0;
  foreach (t : tokens)
  {
    size += t.len;
    if (t[0] != '_') size += 1;
  }
  --size;

  usz last_token_index = tokens.len() - (tokens[^1][0] == '_' ? 2 : 1); 

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  usz last = 0;
  foreach (i, t : tokens)
  {
    bool is_underscore = t[0] == '_';
    res[last:t.len] = t;

    foreach (&c : res[last:t.len])
    {
      *c = c.to_lower();
    }

    if (!is_underscore && i != last_token_index)
    {
      res[last+t.len] = '_';
      ++last;
    }

    last += t.len;
  }

  return res;
}

fn String strCamelToScreaming(String str, Allocator alloc) @inline => @pool()
{
  ListString tokens = parseCamelCase(tmem, str);
  
  usz size = 0;
  foreach (t : tokens)
  {
    size += t.len;
    if (t[0] != '_') size += 1;
  }
  --size;

  usz last_token_index = tokens.len() - (tokens[^1][0] == '_' ? 2 : 1); 

  String res = (String) allocator::alloc_array(alloc, char, size);
  
  usz last = 0;
  foreach (i, t : tokens)
  {
    bool is_underscore = t[0] == '_';

    foreach (j, &c : res[last:t.len])
    {
      *c = t[j].to_upper();
    }

    if (!is_underscore && i != last_token_index)
    {
      res[last+t.len] = '_';
      ++last;
    }

    last += t.len;
  }

  return res;
}

fn String strCamelToPascal(String str, Allocator alloc) @inline
{
  String res = str.copy(alloc);

  usz i;
  while (i < str.len && str[i] == '_') ++i;
  if (i < str.len) res[i] = str[i].to_upper();

  return res;
}

/// ----------------- PASCAL CASE --------------------

alias strPascalToSnake = strCamelToSnake;
alias strPascalToScreaming = strCamelToScreaming;

fn String strPascalToCamel(String str, Allocator alloc) @inline
{
  String res = str.copy(alloc);

  usz i;
  while (i < str.len && str[i] == '_') ++i;
  if (i < str.len) res[i] = str[i].to_lower();

  return res;
}

/// ------------------- Local parsers -------------------

<*
 Example: __one_two__three_ -> [ __ one two three _ ]
 @return "List which must be freed"
*>
fn ListString parseSnakeCase(Allocator alloc, String str) @local
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
  for (usz i = first; i <= last;)
  {
    while (i <= last && str[i] == '_') ++i;
    usz begin = i;
    while (i <= last && str[i] != '_') ++i;
    tokens.push(str[begin..i-1]);
  }

  // Push closing '_'
  if (last < str.len - 1) 
  {
    tokens.push(str[last+1..str.len-1]);
  }

  return tokens;
}

<*
 Example: __oneTWo_threeFOUR -> [ __ one TWo_three FOUR __ ]
 @return "List which then must be freed"
*>
fn ListString parseCamelCase(Allocator alloc, String str) @local
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
  for (usz i = first; i <= last;)
  {
    usz begin = i++;

    // Handle several upper cases in a row
    if (str[begin].is_upper()) while (i <= last && str[i].is_upper()) ++i;

    while (i <= last && ( str[i] == '_' || str[i].is_lower() )) ++i;
    tokens.push(str[begin..i-1]);

    // Handle digits
    begin = i;
    while (i <= last && str[i].is_digit()) ++i;
    if (begin < i) tokens.push(str[begin..i-1]);
  }

  // Push closing '_'
  if (last < str.len - 1) 
  {
    tokens.push(str[last+1..str.len-1]);
  }

  return tokens;
}


