#!/bin/bash

# Copyright (c) 2020 The Khronos Group Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

NUM_CORES=$(nproc)

build() { 
    type=$1
    shift
    args=$@
    mkdir -p build/$type
    pushd build/$type
    echo $args
    emcmake cmake \
        -DCMAKE_BUILD_TYPE=Release \
        $args \
        ../..
    emmake make -j $(( $NUM_CORES )) SPIRV-Tools-static

    echo Building js interface
    emcc \
        --bind \
        -I../../include \
        -std=c++11 \
        ../../source/wasm/spirv-tools.cpp \
        source/libSPIRV-Tools.a \
        -o spirv-tools.js \
        -s MODULARIZE \
        -Oz

    popd
    mkdir -p out/$type

    # copy other js files
    cp source/wasm/spirv-tools.d.ts out/$type/
    cp source/wasm/package.json out/$type/
    cp source/wasm/README.md out/$type/
    cp LICENSE out/$type/

    cp build/$type/spirv-tools.js out/$type/
    gzip -9 -k -f out/$type/spirv-tools.js
    brotli     -f out/$type/spirv-tools.js
    if [ -e build/$type/spirv-tools.wasm ] ; then
       cp build/$type/spirv-tools.wasm out/$type/
       gzip -9 -k -f out/$type/spirv-tools.wasm
       brotli     -f out/$type/spirv-tools.wasm
    fi
}

if [ ! -d external/spirv-headers ] ; then
    echo "Fetching SPIRV-headers"
    git clone https://github.com/KhronosGroup/SPIRV-Headers.git external/spirv-headers
fi

echo Building ${BASH_REMATCH[1]}
build web\
    -DSPIRV_COLOR_TERMINAL=OFF\
    -DSPIRV_SKIP_TESTS=ON\
    -DSPIRV_SKIP_EXECUTABLES=ON

wc -c out/*/*
