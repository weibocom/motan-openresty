# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua::Stream;
use FindBin qw($Bin);
my $root_path = $Bin;
our $MOTAN_P_ROOT=$root_path . "/../lib/";
our $MOTAN_CPATH=$root_path . "/../lib/motan/libs/";
our $MOTAN_DEMO_PATH=$root_path . "/motan-demo/";

our $http_config=<<"_EOC_";
    lua_package_path '$MOTAN_DEMO_PATH/?.lua;$MOTAN_DEMO_PATH/?/init.lua;$MOTAN_P_ROOT/?.lua;$MOTAN_P_ROOT/?/init.lua;./?.lua;/?.lua;/?/init.lua;;';
    lua_package_cpath '$MOTAN_CPATH/?.so;;';
    init_by_lua_block {
        motan = require 'motan'
        motan.init()
    }
_EOC_

$ENV{TEST_NGINX_SERVER_PORT} = 1990;
$ENV{MOTAN_ENV} = "development";
log_level('warn');
#worker_connections(1014);
#master_on();
#workers(2);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 2);
# use Test::Nginx::Socket::Lua::Stream 'no_plan';

# no_diff();
#no_long_string();
run_tests();

# DTYPE_NULL = 0
# DTYPE_STRING = 1
# DTYPE_STRING_MAP = 2
# DTYPE_BYTE_ARRAY = 3
# DTYPE_STRING_ARRAY = 4
# DTYPE_BOOL = 5
# DTYPE_BYTE = 6
# DTYPE_INT16 = 7
# DTYPE_INT32 = 8
# DTYPE_INT64 = 9
# DTYPE_FLOAT32 = 10
# DTYPE_FLOAT64 = 11

# DTYPE_MAP = 20
# DTYPE_ARRAY = 21

__DATA__

=== TEST 1: motan openresty simple serialize - Null
--- http_config eval: $::http_config
--- TODO 
check NULL support
--- SKIP
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = nil
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  0
}

=== TEST 2: motan openresty simple serialize - String
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = '阿波罗a'
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  1,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  97
}

=== TEST 3: motan openresty simple serialize - StringMap
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = {name='阿波罗a'}
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  2,
  0,
  0,
  0,
  22,
  0,
  0,
  0,
  4,
  110,
  97,
  109,
  101,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  97
}

=== TEST 4: motan openresty simple serialize - ByteArray
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 'there is no bytearray in lua.'
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- no_error_log
[warn]

=== TEST 5: motan openresty simple serialize - StringArray
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = {'阿波罗a', '阿波罗b'}
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  4,
  0,
  0,
  0,
  28,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  97,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  98
}

=== TEST 6: motan openresty simple serialize - Bool
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = true
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  5,
  1
}

=== TEST 7: motan openresty simple serialize - Byte
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 1
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  9,
  2
}

=== TEST 8: motan openresty simple serialize - Int16
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 65535
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  9,
  254,
  255,
  7
}

=== TEST 9: motan openresty simple serialize - Int32
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 429496729
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  9,
  178,
  230,
  204,
  153,
  3
}

=== TEST 10: motan openresty simple serialize - Int64
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 7205759403792793
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  9,
  178,
  230,
  204,
  153,
  179,
  230,
  204,
  25
}

=== TEST 11: motan openresty simple serialize - Float32
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 429496729.333333
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  11,
  65,
  185,
  153,
  153,
  153,
  85,
  85,
  80
}

=== TEST 12: motan openresty simple serialize - Float64
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 72057594037927.333333
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  11,
  66,
  208,
  98,
  77,
  210,
  241,
  169,
  213
}

=== TEST 13: motan openresty simple serialize - Map
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local str_arr = {one='阿波罗a'}
            local t_data = {name=str_arr}
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  20,
  0,
  0,
  0,
  35,
  1,
  0,
  0,
  0,
  4,
  110,
  97,
  109,
  101,
  2,
  0,
  0,
  0,
  21,
  0,
  0,
  0,
  3,
  111,
  110,
  101,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  97
}

=== TEST 14: motan openresty simple serialize - Array
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local str_arr_a = {one='阿波罗a'}
            local str_arr_b = {two='阿波罗b'}
            local t_data = {str_arr_a, str_arr_b}
            local bytes = serialize_lib.serialize(t_data)
            ngx.log(ngx.ERR, sprint_r({string.byte(bytes, 1, -1)}))

            local res = sprint_r({string.byte(bytes, 1, -1)})
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
{
  21,
  0,
  0,
  0,
  52,
  2,
  0,
  0,
  0,
  21,
  0,
  0,
  0,
  3,
  111,
  110,
  101,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  97,
  2,
  0,
  0,
  0,
  21,
  0,
  0,
  0,
  3,
  116,
  119,
  111,
  0,
  0,
  0,
  10,
  233,
  152,
  191,
  230,
  179,
  162,
  231,
  189,
  151,
  98
}
