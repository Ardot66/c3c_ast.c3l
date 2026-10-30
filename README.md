# C3C AST
`c3c_ast.c3l` is an experimental library for the C3 programming language that plugs into c3c (the C3 compiler) and provides access to c3c's internal abstract syntax tree (AST). This allows for the development of tools that can effectively act as a custom backend for the c3c compiler.

## C3C Support
Currently C3C _does not_ actually support the feature that this library needs to function. See [this PR](https://github.com/c3lang/c3c/pull/3604) for progress. For the moment, you should be able to play around with this library locally by building from my c3c fork (see the pr).

## Stability Disclaimer
C3 is still a rapidly changing language, and c3c has frequent internal changes that may break your code. If you have issues with completely corrupted data or have pointer dereferences that are failing then the bindings probably need to be regenerated, so please submit an issue or regenerate them locally.

## Usage
For now you can find the public API in [src/c3c_ast.c3](https://github.com/Ardot66/c3c_ast.c3l/blob/main/src/c3c_ast.c3) and AST structures in [c3c.c3i](https://github.com/Ardot66/c3c_ast.c3l/blob/main/c3c.c3i). There are also some handy utils in [src/utils.c3](https://github.com/Ardot66/c3c_ast.c3l/blob/main/src/utils.c3). For a basic use-case, see [test/basic.c3](https://github.com/Ardot66/c3c_ast.c3l/blob/main/test/basic.c3). The root of the AST itself is stored in `ast::context.global`, or with the function `ast::gc()`, and converting `*Id` types should be done with the equivalent `ast::*_ptr()` function.

There is currently no documentation on the AST structures, mainly because they are subject to change, the source file is generated, and documenting them would be a _lot_ of work. All AST structures have equivalents in the [c3c source](https://github.com/c3lang/c3c/blob/master/src/compiler/compiler_internal.h), and for now the best way to figure out what they do is to download c3c and explore the code for yourself.

## Platform Support
This library has only been tested on an x86_64 Linux machine. It probably won't work on Windows at the moment because of the internal use of `mmap`. If you need this library on Windows please submit an issue or PR and I'll try to get to it.

## Installing
To install, just clone this repository into your project's `lib` folder.

## Tests
To run the tests, you will probably need to change the `C3C_PATH` constant in `test/basic.c3` to wherever your installation is. Otherwise, they should run fine with `c3c test`.
