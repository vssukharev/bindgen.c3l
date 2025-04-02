
# bindgen.c3l

C3 library which translates C header files to C3 bindings. It's main idea is to generate C3 binding with minimal manual efforts via one single function.

## API

All API functions are concentrated in *bindgen.c3l/bindgen.c3* file with more detailed documentation.

### Main API

Main library function is `bg::translate_headers`. Mainly it takes a set of headers and translation functions, which you have to write manually. There is also extra functionality which you can see at the docs.

### String API

For better user experience there is additional API for string transformations, which is a submodule of `bindgen`:

- `bgstr::map_basic_type` - switches the passed type and returns the corresponding C3 valid alternative. For example, it maps `uint32_t` -> `uint`, `int` -> `CInt`, etc. Strongly recommended to use every time.
- `bgstr::<case1>_to_<case2>` - a ton of functions to convert one case to another. For instance, `bgstr::pascal_to_snake("HelloWorld")` would return `"hello_world"`. These functions are also defined as methods for `String` for convenience.

## Examples

There are several examples located in `examples` directory. To check them out, run the following command in root directory of the repository:

- My dummy: `c3c run dummy -- ./build/dummy.c3i` or `c3c run dummy` - it will print output to stdout
- Vulkan: `c3c run vulkan -- ./build/vulkan.c3i`
- GLFW: `c3c run glfw -- ./build/glfw.c3i`
- Raylib: `c3c run raylib -- ./build/raylib.c3i`

## Setup

> [!CAUTION]
> Currently c3c is in development so it's not stable. To be sure that you are using a correct version of the compiler, look at the 'flake.lock': "nodes" -> "c3c" -> "lock" -> "rev". 

This library is distributed with source code so you don't have to additionally link statically or dynamically to retrieve functionality.

To get **bindgen.c3l** working, make the following steps:

1. Install [libclang](https://clang.llvm.org/doxygen/group__CINDEX.html) on your system (library for parsing C files).
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
4. Import module `bindgen` into your project. NOTICE: you must prefix functions with `bg`, not `bindgen` module name, for instance: `bg::hello()` but not `bindgen::hello()` - it is made for shorty sake.

## Adding new targets to manifest.json

If your platform is not currently supported, you are free to submit an issue or PR. I am using linux so I don't know how to link with libclang under various platforms, so I would really appreciate your help with that.

First of all, read a [short article](https://c3-lang.org/misc-advanced/library-packaging/) on C3 wiki about library packaging. Then you will need to modify `bindgen.c3l/manifest.json` with adding your target and linking arguments.

## Still have some questions?

Join and contact me in [C3 discord channel](https://discord.com/channels/650345951868747808/1324455225028775946).

