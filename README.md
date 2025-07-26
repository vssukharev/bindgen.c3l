
# bindgen.c3l

C3 library which translates C header files to C3 bindings. It's main idea is to generate C3 binding with minimal manual efforts via one single function.

## Setup

> [!CAUTION]
> Currently c3c is in development so it's not stable. To be sure that you are using a correct version of the compiler, look at the 'flake.lock': "nodes" -> "c3c" -> "lock" -> "rev". 

This library is distributed with source code so you don't have to additionally with it link statically or dynamically.

Dependencies:

- [libclang](https://clang.llvm.org/doxygen/group__CINDEX.html)
- [c3c](https://c3-lang.org/)

Installation steps:

1. Install `libclang` on your system (library for parsing C files).
2. Copy `bindgen.c3l` directory the dependency directory of your c3 project (`lib` by default).
3. You can now set `bindgen` dependency for any project target by doing, for example (for more information plesase refer to C3 wiki):
```json
{
  "targets": {
    "myfoo": {
      "dependencies": [ "bindgen" ],
    },
  },
}
```
4. Import module `bindgen` into your project:
```c3
import bindgen;
```
5. The most basic file if we want to translate a single file *foo.h* to *foo.c3i* without any additional work:
```c3
import bindgen;

fn void main() {
  bg::translate_header("foo.h", { .out_name = "foo.c3i" })!!;
}
```

> [!NOTE]
> you must prefix functions with `bg`, not `bindgen`. For instance: `bg::hello()` but not `bindgen::hello()` - it is made for shorty sake.

## API

All API functions are concentrated in *bindgen.c3l/bindgen.c3* file with more detailed documentation.

### Main API

Main library function is `bg::translate_header`. Mainly it takes a set of headers and translation functions, which you have to write manually. Mostly these functions takes the name of an entity and must return how must this entity be called in C3 file. There is also extra functionality which you can see at the docs.

### String API

For better user experience there is additional API for string transformations, which is a submodule of `bindgen`. These functions are also defined as methods for `String` for convenience:

- `bgstr::<case1>_to_<case2>` - a ton of functions to convert one case to another. For instance, `bgstr::pascal_to_snake("HelloWorld")` will return `"hello_world"`.
- `bgstr::mixed_to_<case2>` - the logic of using it is the same as `bgstr::<case1>_to_<case2>` but it practically sequentially apply both translations for snake and camel case. For instance, `bgstr::mixed_to_screaming("LLVMDisassembler_ReferenceType_In_ARM64_LDRXui")` will return `"LLVM_DISASSEMBLER_REFERENCE_TYPE_IN_ARM64_LDR_XUI"`.
- `bgstr::is_between` - detects whether a name is located between two given names in respect to the order of their translation. **WARNING**: because macros are translated at first even if they are located between, for instance, function declarations, you have to consider it while using this function.

## Examples

There are several examples located in `examples` directory. To check them out, run the following command in root directory of the repository:

- Sandbox to try out library: `c3c run sandbox` - it will write to `build/sandbox.c3i`
- My dummy: `c3c run dummy -- ./build/dummy.c3i` or `c3c run dummy` - it will print output to stdout
- Vulkan: `c3c run vulkan -- ./build/vulkan.c3i`
- GLFW: `c3c run glfw -- ./build/glfw.c3i`
- Raylib: `c3c run raylib -- ./build/raylib.c3i`

## Bit fields translation warning

Bit fields in C are not really ABI-compatible with C3. One thing **bindgen** do is the summing of the sequence of bit fields and emitting the bitstruct represented by a type, which size equals the size of these bit fields. Currently **bindgen** can't consider all the platform ABIs to generate the correct layout, but at least tries to do it in the most simple way. To be confident about the correctness of bit fields translation you need to test the bindings out on various platforms.

## Adding new targets to manifest.json

If your platform is not currently supported, you are free to submit an issue or PR. I am using linux so I don't know how to link with libclang under various platforms, so I would really appreciate your help with that.

First of all, read a [short article](https://c3-lang.org/misc-advanced/library-packaging/) on C3 wiki about library packaging. Then you will need to modify `bindgen.c3l/manifest.json` with adding your target and linking arguments.

## Still have some questions?

Join and contact me in [C3 discord channel](https://discord.com/channels/650345951868747808/1324455225028775946).

## TODO

- Fix floating point suffixes
- Multiple translation units support
- Add kind parameter to if_condition and module_wrap functions: function, structure, member, etc.

