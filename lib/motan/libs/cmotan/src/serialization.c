//
// Created by minggang on 2018/11/9.
//
#include <stdlib.h>
#include "lauxlib.h"

#include "serialization.h"
#include "buffer.h"

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM < 502
/* Compatibility for Lua 5.1.
 *
 * luaL_setfuncs() is used to create a module table where the functions have
 * json_config_t as their first upvalue. Code borrowed from Lua 5.2 source. */
static void luaL_setfuncs (lua_State *l, const luaL_Reg *reg, int nup) {
    int i;

    luaL_checkstack(l, nup, "too many upvalues");
    for (; reg->name != NULL; reg++) {  /* fill the table with given functions */
        for (i = 0; i < nup; i++)  /* copy upvalues to the top */
            lua_pushvalue(l, -nup);
        lua_pushcclosure(l, reg->func, nup);  /* closure with those upvalues */
        lua_setfield(l, -(nup + 2), reg->name);
    }
    lua_pop(l, nup);  /* remove upvalues */
}
#define lua_rawlen(L, n) lua_objlen((L), (n))
#endif

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM < 503
#include <math.h>
int lua_isinteger(lua_State *L, int idx) {
    if (lua_type(L, idx) == LUA_TNUMBER) {
        double k = lua_tonumber(L, idx);
        return floor(k) == k;
    } else {
        return 0;
    }
}
#endif

static int motan_simple_serialize_data(lua_State *L, motan_bytes_buffer_t *mb);

static int motan_simple_deserialize_data(lua_State *L, motan_bytes_buffer_t *mb, uint8_t *type);

int luaopen_cmotan(lua_State *L) {
    luaL_Reg reg[] = {
            {"simple_serialize",   motan_simple_serialize},
            {"simple_deserialize", motan_simple_deserialize},
            {"version",            motan_version},
            {NULL, NULL}
    };

    lua_newtable(L);

    luaL_setfuncs(L, reg, 0);

    lua_pushlightuserdata(L, NULL);
    lua_setfield(L, -2, "null");

    /* Set module name / version fields */
    lua_pushliteral(L, MOTAN_MODNAME);
    lua_setfield(L, -2, "_NAME");
    lua_pushliteral(L, MOTAN_VERSION);
    lua_setfield(L, -2, "_VERSION");

    return 1;
}

static void _write_string(lua_State *L, motan_bytes_buffer_t *mb) {
    size_t len;
    const char *s = lua_tolstring(L, -1, &len);
    mb_write_byte(mb, T_STRING);
    mb_write_uint32(mb, len);
    mb_write_bytes(mb, (const uint8_t *) s, len);
}

static void _write_bool(lua_State *L, motan_bytes_buffer_t *mb) {
    mb_write_byte(mb, T_BOOL);
    if (lua_toboolean(L, -1)) {
        mb_write_byte(mb, 1);
    } else {
        mb_write_byte(mb, 0);
    }
}

static void _write_number(lua_State *L, motan_bytes_buffer_t *mb) {
    if (lua_isinteger(L, -1)) {
        int v_len;
        mb_write_byte(mb, T_INT64);
        mb_write_varint(mb, zigzag_encode(lua_tointeger(L, -1)), &v_len);
    } else {
        mb_write_byte(mb, T_FLOAT64);
        double f = lua_tonumber(L, -1);
        mb_write_uint64(mb, *((uint64_t *) &f));
    }
}

static void _write_string_array(lua_State *L, motan_bytes_buffer_t *mb, int items) {
    mb_write_byte(mb, T_STRING_ARRAY);
    int pos = mb->write_pos;
    mb_set_write_pos(mb, pos + 4);
    for (int i = 1; i <= items; i++) {
        lua_rawgeti(L, -1, i);
        size_t len;
        const char *s = lua_tolstring(L, -1, &len);
        mb_write_uint32(mb, len);
        mb_write_bytes(mb, (const uint8_t *) s, len);
        lua_pop(L, 1);
    }
    int now_pos = mb->write_pos;
    mb_set_write_pos(mb, pos);
    mb_write_uint32(mb, now_pos - pos - 4);
    mb_set_write_pos(mb, now_pos);
}

static int _write_array(lua_State *L, motan_bytes_buffer_t *mb, int items) {
    mb_write_byte(mb, T_ARRAY);
    int pos = mb->write_pos;
    mb_set_write_pos(mb, pos + 4);
    for (int i = 1; i <= items; i++) {
        lua_rawgeti(L, -1, i);
        int err = motan_simple_serialize_data(L, mb);
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            return err;
        }
        lua_pop(L, 1);
    }
    int now_pos = mb->write_pos;
    mb_set_write_pos(mb, pos);
    mb_write_uint32(mb, now_pos - pos - 4);
    mb_set_write_pos(mb, now_pos);
    return MOTAN_OK;
}

static void _write_string_map(lua_State *L, motan_bytes_buffer_t *mb) {
    mb_write_byte(mb, T_STRING_MAP);
    int pos = mb->write_pos;
    mb_set_write_pos(mb, pos + 4);
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        size_t len;
        // For key
        const char *s = lua_tolstring(L, -2, &len);
        mb_write_uint32(mb, len);
        mb_write_bytes(mb, (const uint8_t *) s, len);

        // For value
        s = lua_tolstring(L, -1, &len);
        mb_write_uint32(mb, len);
        mb_write_bytes(mb, (const uint8_t *) s, len);
        lua_pop(L, 1);
    }
    int now_pos = mb->write_pos;
    mb_set_write_pos(mb, pos);
    mb_write_uint32(mb, now_pos - pos - 4);
    mb_set_write_pos(mb, now_pos);
}

static int _write_map(lua_State *L, motan_bytes_buffer_t *mb) {
    mb_write_byte(mb, T_MAP);
    int pos = mb->write_pos;
    mb_set_write_pos(mb, pos + 4);
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        // For key
        // table key value
        lua_pushvalue(L, -2);
        // table key value key
        int err = motan_simple_serialize_data(L, mb);
        if (err != MOTAN_OK) {
            lua_pop(L, 3);
            return err;
        }
        lua_pop(L, 1);

        // For value
        // table key value
        err = motan_simple_serialize_data(L, mb);
        lua_pop(L, 1);
        // table key
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            return err;
        }
    }
    int now_pos = mb->write_pos;
    mb_set_write_pos(mb, pos);
    mb_write_uint32(mb, now_pos - pos - 4);
    mb_set_write_pos(mb, now_pos);
    return MOTAN_OK;
}

static int _write_table(lua_State *L, motan_bytes_buffer_t *mb) {
    int is_array = 1;
    int keys_are_string = 1;
    int values_are_string = 1;
    int items = 0;
    // table 类型判断规则
    // 如果key都为整型，value都为字符串则使用string_array
    // 如果key都为整型，value包含非字符串则使用array
    // 如果key都为字符串，value都为字符串则使用string_map
    // 如果key包含非字符串或value包含非字符串则使用map
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        /* table, key, value */
        int k_type = lua_type(L, -2);
        int v_type = lua_type(L, -1);
        items++;
        if (lua_isinteger(L, -2)) {
            if (lua_tonumber(L, -2) < 1) {
                is_array &= 0;
            }
        } else {
            is_array &= 0;
        }

        if (k_type != LUA_TSTRING) {
            keys_are_string &= 0;
        }

        // TODO: if value is null
        if (v_type != LUA_TSTRING) {
            values_are_string &= 0;
        }
        lua_pop(L, 1);
        // table key
        if (!is_array && !values_are_string ) {
            lua_pop(L, 1);
            return _write_map(L, mb);
        }
    }
    // empty table we treat as null
    if (items == 0) {
        mb_write_byte(mb, T_NULL);
        return MOTAN_OK;
    }

    if (is_array) {
        if (values_are_string) {
            _write_string_array(L, mb, items);
            return MOTAN_OK;
        } else {
            return _write_array(L, mb, items);
        }
    }

    // now type is map and values are string
    if (keys_are_string) {
        _write_string_map(L, mb);
    } else {
        _write_map(L, mb);
    }
    return MOTAN_OK;
}

static int motan_simple_serialize_data(lua_State *L, motan_bytes_buffer_t *mb) {
    switch (lua_type(L, -1)) {
        case LUA_TSTRING:
            _write_string(L, mb);
            return MOTAN_OK;
        case LUA_TNUMBER:
            _write_number(L, mb);
            return MOTAN_OK;
        case LUA_TBOOLEAN:
            _write_bool(L, mb);
            return MOTAN_OK;
        case LUA_TTABLE:
            return _write_table(L, mb);
        case LUA_TNIL:
            mb_write_byte(mb, T_NULL);
            return MOTAN_OK;
        default:
            return E_MOTAN_UNSUPPORTED_TYPE;
    }
}

int motan_simple_serialize(lua_State *L) {
    int n = lua_gettop(L);    /* number of arguments */
    if (n == 0) {
        lua_pushstring(L, "");
        return 1;
    }
    if (!lua_istable(L, 1)) {
        luaL_error(L, "the simple serialization parameter must be an array that contains all real input parameters");
    }
    motan_bytes_buffer_t *mb = motan_new_bytes_buffer(4096, M_BIG_ENDIAN);
    if (mb == NULL) {
        luaL_error(L, "%s", motan_error(E_MOTAN_MEMORY_NOT_ENOUGH));
    }
    int n_params = lua_rawlen(L, 1);
    for (int i = 1; i <= n_params; i++) {
        lua_rawgeti(L, 1, i);
        int err = motan_simple_serialize_data(L, mb);
        lua_pop(L, 1);
        if (err != MOTAN_OK) {
            motan_free_bytes_buffer(mb);
            luaL_error(L, "%s", motan_error(err));
        }
    }
    lua_pushlstring(L, (const char *) mb->buffer, mb->write_pos); // first result
    motan_free_bytes_buffer(mb);
    return 1; // number of results
}

static int _read_bool(lua_State *L, motan_bytes_buffer_t *mb) {
    uint8_t b;
    int err = mb_read_byte(mb, &b);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushboolean(L, b);
    return MOTAN_OK;
}

static int _read_null(lua_State *L, __unused motan_bytes_buffer_t *mb) {
    // for nil value table will remove it, here we put a userdata
    lua_pushlightuserdata(L, NULL);
    return MOTAN_OK;
}

static int _read_string(lua_State *L, motan_bytes_buffer_t *mb) {
    uint32_t len;
    int err = mb_read_uint32(mb, &len);
    if (err != MOTAN_OK) {
        return err;
    }
    uint8_t *bs = (uint8_t *) malloc(len);
    if (bs == NULL) {
        die("Out of memory");
    }
    err = mb_read_bytes(mb, bs, len);
    if (err != MOTAN_OK) {
        free(bs);
        return err;
    }
    lua_pushlstring(L, (const char *) bs, len);
    free(bs);
    return MOTAN_OK;
}

static int _read_byte(lua_State *L, motan_bytes_buffer_t *mb) {
    uint8_t b;
    int err = mb_read_byte(mb, &b);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushinteger(L, b);
    return MOTAN_OK;
}

static int _read_int16(lua_State *L, motan_bytes_buffer_t *mb) {
    uint16_t u;
    int err = mb_read_uint16(mb, &u);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushinteger(L, u);
    return MOTAN_OK;
}

static int _read_int32(lua_State *L, motan_bytes_buffer_t *mb) {
    uint64_t u;
    int err = mb_read_varint(mb, &u);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushinteger(L, zigzag_decode(u));
    return MOTAN_OK;
}

static int _read_int64(lua_State *L, motan_bytes_buffer_t *mb) {
    uint64_t u;
    int err = mb_read_varint(mb, &u);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushinteger(L, zigzag_decode(u));
    return MOTAN_OK;
}

static int _read_float32(lua_State *L, motan_bytes_buffer_t *mb) {
    uint32_t u;
    int err = mb_read_uint32(mb, &u);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushnumber(L, *((float *) &u));
    return MOTAN_OK;
}

static int _read_float64(lua_State *L, motan_bytes_buffer_t *mb) {
    uint64_t u;
    int err = mb_read_uint64(mb, &u);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_pushnumber(L, *((double *) &u));
    return MOTAN_OK;
}

static int _read_string_map(lua_State *L, motan_bytes_buffer_t *mb) {
    uint32_t len;
    int err = mb_read_uint32(mb, &len);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_newtable(L);
    uint32_t end_pos = mb->read_pos + len;
    while (mb->read_pos < end_pos) {
        // table
        err = _read_string(L, mb);
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            return err;
        }
        // table key
        err = _read_string(L, mb);
        if (err != MOTAN_OK) {
            lua_pop(L, 2);
            return err;
        }
        // table key value
        lua_rawset(L, -3);
    }

    if (mb->read_pos != end_pos) {
        lua_pop(L, 1);
        return E_MOTAN_WRONG_SIZE;
    }

    return MOTAN_OK;
}

static int _read_map(lua_State *L, motan_bytes_buffer_t *mb) {
    uint32_t len;
    int err = mb_read_uint32(mb, &len);
    if (err != MOTAN_OK) {
        return err;
    }
    lua_newtable(L);
    uint32_t end_pos = mb->read_pos + len;
    while (mb->read_pos < end_pos) {
        // table
        uint8_t type;
        err = motan_simple_deserialize_data(L, mb, &type);
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            return err;
        }
        // table key
        err = motan_simple_deserialize_data(L, mb, &type);
        if (err != MOTAN_OK) {
            lua_pop(L, 2);
            return err;
        }
        // table key value
        lua_rawset(L, -3);
    }
    if (mb->read_pos != end_pos) {
        lua_pop(L, 1);
        return E_MOTAN_WRONG_SIZE;
    }
    return MOTAN_OK;
}

static int _read_byte_array(lua_State *L, motan_bytes_buffer_t *mb) {
    return _read_string(L, mb);
}

static int _read_string_array(lua_State *L, motan_bytes_buffer_t *mb) {
    uint32_t len;
    int err = mb_read_uint32(mb, &len);
    if (err != MOTAN_OK) {
        return err;
    }
    int count = 1;
    lua_newtable(L);
    uint32_t end_pos = mb->read_pos + len;
    while (mb->read_pos < end_pos) {
        err = _read_string(L, mb);
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            return err;
        }
        lua_rawseti(L, -2, count);
        count++;
    }
    if (mb->read_pos != end_pos) {
        lua_pop(L, 1);
        return E_MOTAN_WRONG_SIZE;
    }
    return MOTAN_OK;
}

static int _read_array(lua_State *L, motan_bytes_buffer_t *mb) {
    uint32_t len;
    int err = mb_read_uint32(mb, &len);
    if (err != MOTAN_OK) {
        return err;
    }
    int count = 1;
    lua_newtable(L);
    uint32_t end_pos = mb->read_pos + len;
    while (mb->read_pos < end_pos) {
        uint8_t type;
        err = motan_simple_deserialize_data(L, mb, &type);
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            return err;
        }
        lua_rawseti(L, -2, count);
        count++;
    }
    if (mb->read_pos != end_pos) {
        lua_pop(L, 1);
        return E_MOTAN_WRONG_SIZE;
    }
    return MOTAN_OK;
}

static int motan_simple_deserialize_data(lua_State *L, motan_bytes_buffer_t *mb, uint8_t *type) {
    int err = mb_read_byte(mb, type);
    if (err != MOTAN_OK) {
        return err;
    }
    switch (*type) {
        case T_BOOL:
            return _read_bool(L, mb);
        case T_NULL:
            return _read_null(L, mb);
        case T_STRING:
            return _read_string(L, mb);
        case T_STRING_MAP:
            return _read_string_map(L, mb);
        case T_BYTE_ARRAY:
            return _read_byte_array(L, mb);
        case T_STRING_ARRAY:
            return _read_string_array(L, mb);
        case T_BYTE:
            return _read_byte(L, mb);
        case T_INT16:
            return _read_int16(L, mb);
        case T_INT32:
            return _read_int32(L, mb);
        case T_INT64:
            return _read_int64(L, mb);
        case T_FLOAT32:
            return _read_float32(L, mb);
        case T_FLOAT64 :
            return _read_float64(L, mb);
        case T_MAP:
            return _read_map(L, mb);
        case T_ARRAY:
            return _read_array(L, mb);
        default:
            return E_MOTAN_UNSUPPORTED_TYPE;
    }
}

int motan_simple_deserialize(lua_State *L) {
    luaL_argcheck(L, lua_gettop(L) == 1, 1, "expected 1 argument");
    size_t len;
    const char *bs = luaL_checklstring(L, 1, &len);
    motan_bytes_buffer_t *mb = motan_new_bytes_buffer_from_bytes((uint8_t *) bs, len, M_BIG_ENDIAN, 1);
    int count = 1;
    lua_newtable(L);
    while (mb_remain(mb) > 0) {
        uint8_t type;
        int err = motan_simple_deserialize_data(L, mb, &type);
        if (err != MOTAN_OK) {
            lua_pop(L, 1);
            motan_free_bytes_buffer(mb);
            luaL_error(L, "%s", motan_error(err));
        }
        lua_rawseti(L, -2, count);
        count++;
    }
    motan_free_bytes_buffer(mb);
    return 1;
}
