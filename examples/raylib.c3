
import bindgen;

// There is one problem with automatic raylib bindings generation.
// Defined colors (like LIGHTGRAY) are defined as macros with really
// specific signature with functional macro usage. Bindgen have no
// idea about their types and can't infer them as raylib uses 
// '#define YELLOW CLITERAL(Color){ 253, 249, 0, 255 }' for example.
// So the solution is to modify 'raylib.h' to avoid performing of
// modifications manually every time

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


fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGTransCallbacks cbs = {
    .func = &bgstr::pascal_to_camel,

    .type = fn String(String str, Allocator alloc) =>
      str.map_basic_type(alloc) ?? str.camel_to_pascal(alloc),

    .func_macro = fn String(String str, Allocator alloc) =>
       str == "CLITERAL" || str[:3] == "RL_" ? "" : str.screaming_to_camel(alloc),

    .variable = fn String(String str, Allocator alloc) =>
      str == "alias" ? "" : str.copy(alloc),

    .constant = &transConst,
  };

  BGOptions opts = {
    .out_name = out,
    .module_name = "raylib::rl",
  };

  bg::translate_header("./examples/headers/raylib.h", cbs, opts)!!;
}

