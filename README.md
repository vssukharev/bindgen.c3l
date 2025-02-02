
# bindgen.c3l

WIP C bindings generation library for C3 language. 

## TODO

- Add unions translation
- Get rid of bug in typedef alias translation

## Setup

1. Copy `bindgen.c3l` directory the dependency directory of your c3 project (`lib` by default).
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

## Usage

See `examples/hello.c3` (`c3c run hello` to immediately run example).

## Adding new targets

If your platform is not currently supported, you are free to submit an issue or PR. I am using linux so I don't know how to link with libclang under various platforms, so I would really appreciate your help with that.

First of all, read a [short article](https://c3-lang.org/misc-advanced/library-packaging/) on C3 wiki about library packaging. Then you will need to modify `bindgen.c3l/manifest.json` with adding your target and linking arguments.


