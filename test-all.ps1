$ErrorActionPreference = 'Stop'

$env:CMAKE_GENERATOR = "Visual Studio 17 2022"
$env:CMAKE_PREFIX_PATH = "$pwd/_local"
$env:CMAKE_INSTALL_PREFIX = "$pwd/_local"

cmake -S . -B build/cppfront
cmake --build build/cppfront --target install --config Release

cmake -S example -B build/example
cmake --build build/example --config Release
./build/example/Release/main
cmake -E cat xyzzy

cmake -S regression-tests -B build/regression-tests
cmake --build build/regression-tests --config Release
ctest --test-dir build/regression-tests -C Release --output-on-failure -j "$env:NUMBER_OF_PROCESSORS"
