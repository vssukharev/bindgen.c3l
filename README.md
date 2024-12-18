
# bindgen.c3l

C bindings generation library for C3 language. 

# Usage

1. Copy `bindgen.c3l` directory and each `.c3l` from `deps` to the dependency directory of your c3 project.
2. You can now set `bindgen` dependency for any project target by doing, for example (for more information plesase refer to C3 wiki):
```json
{
  "targets": {
    "myfoo": {
      "dependencies": [ "bindgen" ],
    },
  },
}
```
3. Import the module into your project. NOTICE: you must prefix functions with `bg`, not `bindgen` module name, for instance: `bg::hello()` but not `bindgen::hello()` - it is made for shorty sake.

