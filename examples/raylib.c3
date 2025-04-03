
import bindgen;
import std::io;

fn String transConst(String name, Allocator alloc)
{
  switch (name)
  {
    // Ignore these constants (constant macros)
    case "GetMouseRay":
    case "MOUSE_LEFT_BUTTON":
    case "MOUSE_RIGHT_BUTTON":
    case "MOUSE_MIDDLE_BUTTON":
    case "MATERIAL_MAP_DIFFUSE":
    case "MATERIAL_MAP_SPECULAR":
    case "SHADER_LOC_MAP_DIFFUSE":
    case "SHADER_LOC_MAP_SPECULAR":
      return "";

    default:
      return name.strip("RAYLIB_").snake_to_screaming(alloc);
  }
}

// There is one problem with automatic raylib bindings generation.
// Defined colors (like LIGHTGRAY) are defined as macros with really
// specific signature with functional macro usage. Bindgen have no
// idea about their types and can't infer them as raylib uses 
// '#define YELLOW CLITERAL(Color){ 253, 249, 0, 255 }' for example.
// So the solution is to create custom const value generation function
// and pass it toy bidngen
fn String valConst(String name, Allocator alloc)
{
  switch (name)
  {
    case "LIGHTGRAY":   return "(Color){ 200, 200, 200, 255 }";
    case "GRAY":        return "(Color){ 130, 130, 130, 255 }";
    case "DARKGRAY":    return "(Color){ 80, 80, 80, 255 }";
    case "YELLOW":      return "(Color){ 253, 249, 0, 255 }";
    case "GOLD":        return "(Color){ 255, 203, 0, 255 }";
    case "ORANGE":      return "(Color){ 255, 161, 0, 255 }";
    case "PINK":        return "(Color){ 255, 109, 194, 255 }";
    case "RED":         return "(Color){ 230, 41, 55, 255 }";
    case "MAROON":      return "(Color){ 190, 33, 55, 255 }";
    case "GREEN":       return "(Color){ 0, 228, 48, 255 }";
    case "LIME":        return "(Color){ 0, 158, 47, 255 }";
    case "DARKGREEN":   return "(Color){ 0, 117, 44, 255 }";
    case "SKYBLUE":     return "(Color){ 102, 191, 255, 255 }";
    case "BLUE":        return "(Color){ 0, 121, 241, 255 }";
    case "DARKBLUE":    return "(Color){ 0, 82, 172, 255 }";
    case "PURPLE":      return "(Color){ 200, 122, 255, 255 }";
    case "VIOLET":      return "(Color){ 135, 60, 190, 255 }";
    case "DARKPURPLE":  return "(Color){ 112, 31, 126, 255 }";
    case "BEIGE":       return "(Color){ 211, 176, 131, 255 }";
    case "BROWN":       return "(Color){ 127, 106, 79, 255 }";
    case "DARKBROWN":   return "(Color){ 76, 63, 47, 255 }";
    case "WHITE":       return "(Color){ 255, 255, 255, 255 }";
    case "BLACK":       return "(Color){ 0, 0, 0, 255 }";
    case "BLANK":       return "(Color){ 0, 0, 0, 0 }";
    case "MAGENTA":     return "(Color){ 255, 0, 255, 255 }";
    case "RAYWHITE":    return "(Color){ 245, 245, 245, 255 }";
    default:            return "";
  }
}

fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGTransCallbacks trans_fns = {
    .func = &bgstr::pascal_to_camel,

    .type = fn String(String str, Allocator alloc) =>
      str.map_basic_type(alloc) ?? str.camel_to_pascal(alloc),

    .func_macro = fn String(String str, Allocator alloc) =>
       str == "CLITERAL" || str[:3] == "RL_" ? "" : 
       str.screaming_to_camel(alloc),

    .variable = fn String(String str, Allocator alloc) =>
      str == "alias" ? "" : str.copy(alloc),

    .constant = &transConst,
  };

  BGGenCallbacks gen_fns = {
    .constant = &valConst,
  };

  BGOptions opts = {
    .out_name = out,
    .module_name = "raylib::rl",
  };

  bg::translate_header("./examples/headers/raylib.h", trans_fns, opts, gen_fns)!!;
}

