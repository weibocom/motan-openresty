//
// Created by minggang on 2018/11/9.
//

#ifndef MOTAN_LUA_MOTAN_H
#define MOTAN_LUA_MOTAN_H

#include "lua.h"

#define MOTAN_OK 0
#define E_MOTAN_BUFFER_NOT_ENOUGH -1
#define E_MOTAN_OVERFLOW -2
#define E_MOTAN_UNSUPPORTED_TYPE -3
#define E_MOTAN_MEMORY_NOT_ENOUGH -4
#define E_MOTAN_WRONG_SIZE -5

#define MOTAN_MODNAME "cmotan"
#ifndef MOTAN_REVISION
#define MOTAN_REVISION ""
#endif
#define MOTAN_VERSION "0.0.1" MOTAN_REVISION

#ifndef __unused
#define __unused __attribute__((unused))
#endif

extern int luaopen_cmotan(lua_State *L);

static inline int motan_version(lua_State *L) {
    lua_pushstring(L, MOTAN_VERSION);
    return 1;
}

__unused static const char *motan_error(int err) {
    switch (err) {
        case MOTAN_OK:
            return "ok";
        case E_MOTAN_BUFFER_NOT_ENOUGH:
            return "motan buffer not enough";
        case E_MOTAN_OVERFLOW:
            return "motan number overflow";
        case E_MOTAN_UNSUPPORTED_TYPE:
            return "motan unsupported type";
        case E_MOTAN_MEMORY_NOT_ENOUGH:
            return "motan memory not enough";
        case E_MOTAN_WRONG_SIZE:
            return "motan wrong data size";
        default:
            return "unknown error";
    }
}

#endif //MOTAN_LUA_MOTAN_H
