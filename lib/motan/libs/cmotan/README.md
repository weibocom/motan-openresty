# motan openresty native library

This is a C extension for motan openresty, for a better perfomance.

Now this project just contain the simple serialization handler.

Use `build_by_docker.sh` to build this library and there will be `cmotan.so` generated in `docker_build` direcotry.
You should copy this file into your openresty lua cpath.

