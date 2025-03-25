
module bindgen::impl::api @private;
import bindgen::impl @public;
import std::collections::list, std::ascii;

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

fn String strTranslateType(String str, Allocator alloc) @inline
{
  switch (str)
  {
    case "void": return "void".copy(alloc);
    case "int": return "CInt".copy(alloc);
    case "long long": return "CLongLong".copy(alloc);
    case "short": return "CShort".copy(alloc);
    case "char": return "CChar".copy(alloc);
    case "float": return "float".copy(alloc);
    case "double": return "double".copy(alloc);
    case "unsigned": return "CUInt".copy(alloc);
    case "unsigned int": return "CUInt".copy(alloc);
    case "unsigned short": return "CUShort".copy(alloc);
    case "unsigned char": return "CUChar".copy(alloc);
    case "int8_t": return "ichar".copy(alloc);
    case "int16_t": return "short".copy(alloc);
    case "int32_t": return "int".copy(alloc);
    case "int64_t": return "long".copy(alloc);
    case "uint8_t": return "char".copy(alloc);
    case "uint16_t": return "ushort".copy(alloc);
    case "uint32_t": return "uint".copy(alloc);
    case "uint64_t": return "ulong".copy(alloc);
  }

  return api::strCapitalizeFirst(str, alloc);
}

<*
 Example: __one_two__three_ -> [ __ one two three _ ]
 @return "List which must be freed"
*>
fn ListString strParseSnakeCase(Allocator alloc, String str) @local
{
  ListString tokens;
  tokens.init(alloc, str.len / 2);

  // Treat possible beginning '_'
  usz first = 0;
  while (first < str.len && str[first] == '_') ++first;
  if (first > 0) tokens.push(str[0..first-1]);

  // And one token
  usz begin = first;
  while (first < str.len && str[first] != '_') ++first;
  tokens.push(str[begin..first-1]);

  // Treat possible closing '_' 
  usz last = str.len - 1;
  while (last > 0 && str[last] == '_') --last;

  // Treat the rest [first..last]
  for (usz i = first; i <= last; ++i)
  {
    while (i <= last && str[i] == '_') ++i;
    begin = i;
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


fn String strSnakeToCamel(String str, Allocator alloc) @inline
{
  ListString tokens = strParseSnakeCase(tmem, str);
  defer tokens.free();
  
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
    last += t.len;
  }

  return res;
}

fn String strSnakeToPascal(String str, Allocator alloc) @inline
{
  ListString tokens = strParseSnakeCase(tmem, str);
  defer tokens.free();
  
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

fn String strScreamingToCamel(String str, Allocator alloc)
{
  ListString tokens = strParseSnakeCase(tmem, str);
  defer tokens.free();
  
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

fn String strScreamingToPascal(String str, Allocator alloc)
{
  ListString tokens = strParseSnakeCase(tmem, str);
  defer tokens.free();
  
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


<*
 Example: __OneTwoThree__ -> [ __One Two Three __ ]
 @return "List which then must be freed"
*>
fn ListString strParsePascalCase(Allocator, String str)
{
  return {};
}

fn String strPascalToSnake(String str, Allocator alloc) @inline
{
  return "";
}

alias strCamelToSnake = strPascalToSnake;

