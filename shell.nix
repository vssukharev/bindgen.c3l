{ 
  mkShell,
  libclang,
  c3c,
}: 
mkShell {
  buildInputs = [
    c3c
    libclang.lib
  ];

  CPATH = builtins.concatStringsSep ":" [ "${libclang.dev}/include" ];
  LIBRARY_PATH = builtins.concatStringsSep ":" [ "${libclang.lib}/lib" ];
}

