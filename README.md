# cppfront cmake wrapper

[![CI](https://github.com/modern-cmake/cppfront/actions/workflows/ci.yml/badge.svg)](https://github.com/modern-cmake/cppfront/actions/workflows/ci.yml)

This is a wrapper around Herb Sutter's [cppfront](https://github.com/hsutter/cppfront)
compiler. Go there to learn more about that project.

This repository adds a CMake build with some "magic" helpers to make it easier to use cpp2.

Requires CMake 3.23+.

**Disclaimer:** As `cppfront` is highly experimental, expect abrupt, backwards-incompatible changes to be made here,
too. This isn't a production-ready ecosystem, and breaking changes will be made if they improve the overall project.
We're on [major-version 0](https://semver.org/#spec-item-4) for the foreseeable future.

**Note:** This work might one day be merged upstream. The open pull request is
here: https://github.com/hsutter/cppfront/pull/15

## Getting started

See the [example](/example) for a full example project.

### Find package

This is the workflow I will personally support.

Build this repository:

```
$ git clone --recursive https://github.com/modern-cmake/cppfront
$ cmake -S cppfront -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/wherever
$ cmake --build build --target install
```

Now just write your project like normal:

```cmake
cmake_minimum_required(VERSION 3.23)
project(example)

find_package(cppfront REQUIRED)

add_executable(main main.cpp2)
```

And that's literally it. Any targets with a `.cpp2` source will automatically
get custom commands added to them.

### FetchContent

FetchContent is also supported, though as always with FetchContent, there's a
chance it will be wonky.

Here's the code.

```cmake
cmake_minimum_required(VERSION 3.23)
project(example)

include(FetchContent)

FetchContent_Declare(
    cppfront
    GIT_REPOSITORY https://github.com/modern-cmake/cppfront.git
    GIT_TAG main  # or an actual git SHA if you don't like to live dangerously
)

FetchContent_MakeAvailable(cppfront)

add_executable(main main.cpp2)
```

The same automatic configuration will happen here, too. Though since
`FetchContent_MakeAvailable` will only run our `CMakeLists.txt` once, the magic
can only happen in the first directory to include it. Thus, you should probably
explicitly run `cppfront_enable(TARGETS main)` and add `set(CPPFRONT_NO_MAGIC 1)`
if you want your project to be consumable via FetchContent. Blech.

You can, of course, use this repo as a submodule and call `add_subdirectory`
rather than using `FetchContent`. It's basically the same except FC has some
overriding mechanism now, as of 3.24.

I won't personally address issues for FetchContent users. PRs are welcome, but
please know CMake well.

## CMake documentation

No matter how you use this CMake build, it exposes the following points of configuration:

### Targets

* `cppfront::cppfront` -- this is the executable for the cppfront compiler
* `cppfront::cpp2util` -- this is an `INTERFACE` library providing the path to the `cpp2util.h` runtime header.

### Options

Universal:

* `CPPFRONT_NO_MAGIC` -- off by default. When enabled, skips the automatic `cpp2`-to-`cpp` translation.
* `CPPFRONT_FLAGS` -- a semicolon-separated list of additional flags to pass to `cppfront`. For now, these are assumed
  to be universal to a project, and it is not supported to change them after the package has loaded, whether
  via `find_package`, `add_subdirectory`, FetchContent, or any other mechanism.

FetchContent-only:

* `CPPFRONT_NO_SYSTEM` -- off by default. When enabled, skips marking the `cpp2util.h` header as `SYSTEM`, meaning that
  warnings generated by that header will be shown.
* `CPPFRONT_INSTALL_RULES` -- off by default. When enabled, runs the `install()` and packaging rules. Everything is
  placed in a component named `cppfront`.

### Variables

* `CPPFRONT_EXECUTABLE` -- `find_package`-only. This is the absolute path to the `cppfront` executable file. This is
  sometimes useful in limited scenarios where neither the `cppfront::cppfront` target, nor
  the `$<TARGET_FILE:cppfront::cppfront>` generator expression can be used.

### Functions

```cmake
cppfront_generate_files(<OUTVAR> <cpp2 files>...)
```

Writes to the variable named by `OUTVAR` a list of absolute paths to the generated `.cpp` files associated with
each `.cpp2` file in the arguments list. A hashing scheme prevents `cppfront` from running on the same `.cpp2` file
multiple times.

```cmake
cppfront_enable_targets(<targets>...)
```

Scans the `SOURCES` properties for each target in `<targets>` for entries ending in `.cpp2`. These are passed
to `cppfront_generate_cpp` and the results are added to the target automatically. When `CPPFRONT_NO_MAGIC` is
unset (i.e. by default), this command runs on all targets in the directory that imported this package at the end of
processing the directory.

```cmake
cppfront_enable_directories(<directories>...)
```

Recursively scans all targets inside `<directories>` and calls `cppfront_enable_targets` for them.

### Developers

The CMake project `regression-tests/CMakeLists.txt` runs the test suite of cppfront.
See "Regression tests" at [`./.github/workflows/ci.yml`](./.github/workflows/ci.yml) for how to set it up.
To have the test results updated, configure with `-DCPPFRONT_DEVELOPING=TRUE`.
