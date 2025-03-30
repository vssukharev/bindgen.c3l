
# bindgen.c3l

WIP C bindings generation library for C3 language. 


## TODO

1. Add FULL Vulkan headers translation example
2. Add comprehensive test suite
3. Add support for inlined enums
4. Add C doc comments support 

## Setup

> [!CAUTION]
> Currently c3c is in development so it's not stable. To be sure that you are using a correct version of the compiler, look at the 'flake.lock': "nodes"- > "c3c" -> "lock" -> "rev". 

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
4. Import the module into your project. NOTICE: you must prefix functions with `bg`, not `bindgen` module name, for instance: `bg::hello()` but not `bindgen::hello()` - it is made for shorty sake.

## Examples

There are some examples provided by me:
- Vulkan header: `c3c run vulkan -- ./build/vulkan.c3i`
- GLFW header: `c3c run glfw -- ./build/glfw.c3i`
- My own dummy header: `c3c run dummy -- ./build/dummy.c3i`

## Adding new targets

If your platform is not currently supported, you are free to submit an issue or PR. I am using linux so I don't know how to link with libclang under various platforms, so I would really appreciate your help with that.

First of all, read a [short article](https://c3-lang.org/misc-advanced/library-packaging/) on C3 wiki about library packaging. Then you will need to modify `bindgen.c3l/manifest.json` with adding your target and linking arguments.


