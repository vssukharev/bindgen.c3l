
import bindgen, bgimpl;
import std::core::ascii, std::io;


fn void main(String[] args)
{
  String out = args.len > 1 ? args[1] : "";
  
  BGOptions opts = {
    .out_name = out,
    .module_name = "mlir",
    .include_file = fn (path) => path.contains("mlir-c"),
    .clang_args = {
      "-I./examples/headers",
    },
    .skip_errors = true,
  };

  BGTransCallbacks transfns = {
    .func = fn (name, alloc) {
      return name.strip_prefix("mlir").camel_to_snake(alloc);
    },

    .constant = fn (name, alloc) {
      switch {
        case name.contains("DEFINE_C_API_STRUCT"):
          return "";
      }

      switch (name) {
        case "MLIR_CAPI_EXPORTED":
          return "";
      }
      if (is_screaming(name)) return name;
      return name.strip_prefix("Mlir").pascal_to_screaming(alloc);
    },

    .enum_field = &bgstr::pascal_to_screaming,

    .func_macro = fn (name, alloc) {
      switch {
        case name.contains("DECLARE_CAPI_DIALECT_REGISTRATION"):
        case name.contains("DEFINE_C_API_STRUCT"):
          return "";
      }
      return name;
    },

    .variable = fn (name, alloc) {
      switch (name) {
        case "module": return "module_";
      }
      return name.camel_to_snake(alloc);
    },

    .type = fn (name, alloc) {
      return name.strip_prefix("Mlir").prepend(alloc, "MLIR");
    }
  };

  bg::translate_header("./examples/headers/mlir-c/Entrance.h", opts, transfns)!!;
}

fn String String.prepend(self, Allocator alloc, String prefix) => @pool()
{
    DString out;
    out.tinit();

    out.append_string(prefix);
    out.append_string(self);

    return out.str_view().copy(alloc);
}

fn bool is_screaming(String name)
{
    return name == "MLIR_ENABLE_EXPENSIVE_PATTERN_API_CHECKS" ||
           name == "MLIR_ENABLE_PDL_IN_PATTERNMATCH" ||
           name == "MLIR_ENABLE_NVPTXCOMPILER" ||
           name == "MLIR_ENABLE_ROCM_CONVERSIONS" ||
           name == "MLIR_CAPI_DWARF_ADDRESS_SPACE_NULL";
}
