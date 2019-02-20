//
// Created by minggang on 2018/11/10.
//

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lualib.h"
#include "lauxlib.h"

#ifdef __APPLE__
#define DL_SUFFIX "dylib"
#else
#define DL_SUFFIX "so"
#endif

int main() {
    static char cpath[1024];
#ifdef __linux__
#include <libgen.h>
    static char exe_path[1024];
    readlink("/proc/self/exe", exe_path, sizeof(exe_path));
    strcpy(cpath, (const char*) dirname(exe_path));
#else
    getcwd(cpath, sizeof(cpath));
#endif
    strcat(cpath, "/libmotan." DL_SUFFIX);
    setenv("LUA_CPATH", cpath, 1);
    fprintf(stderr, "LUA_CPATH: %s\n", cpath);
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    int stat = luaL_dofile(L, "test.lua");
    if (stat != 0) {
        printf("loadfile fail, result: %s\n", lua_tostring(L,-1));
    }
    lua_close(L);
    return 0;
}
