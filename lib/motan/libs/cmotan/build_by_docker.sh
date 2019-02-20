#!/usr/bin/env bash
base_dir=$(dirname $(cd $(dirname "$0") && pwd -P)/$(basename "$0"))

docker run --rm -it -v ${base_dir}/:/src \
-e LD_LIBRARY_PATH=/usr/local/lib \
-v ${base_dir}/test.lua:/data1/test.lua \
-v ${base_dir}/docker_build:/build luominggang/luajit-dev:2.0.5 \
sh -c 'cd /build && rm -rf * && cmake /src && make && cp /build/libmotan.so /build/cmotan.so && /build/serialization_unittest'
