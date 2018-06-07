# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua::Stream;
use FindBin qw($Bin);
my $root_path = $Bin;
our $MOTAN_P_ROOT=$root_path . "/../lib";

$ENV{TEST_NGINX_SERVER_PORT} = 1990;
log_level('warn');
#worker_connections(1014);
#master_on();
#workers(2);

repeat_each(2);

plan tests => repeat_each(2) * (blocks() * 3);

# no_diff();
#no_long_string();
run_tests();

__DATA__

=== TEST 1: pack_request_id
--- stream_config eval
    "lua_package_path '$::MOTAN_P_ROOT/?.lua;$::MOTAN_P_ROOT/?/init.lua;./?.lua;/?.lua;/?/init.lua';"
--- stream_server_config
    preread_by_lua_block {
            local test_data = require "t.lib.data"
            local data = test_data.get_data()
            local utils = require "motan.utils"
            local bytes = utils.pack_request_id(data)
            ngx.log(ngx.WARN, table.concat({string.byte(bytes, 1, -1)}, ","))
            ngx.say(table.concat({string.byte(bytes, 1, -1)}, ","))
            ngx.say("done")
    }
    content_by_lua return;
--- stream_request
72057594037927940
--- stream_response
got the request socket
received: 72057594037927940
1,0,0,0,0,0,0,4
done
--- no_error_log
[error]
--- timeout: 10
--- ONLY

=== TEST 2: ffi pack_request_id
--- stream_config eval
    "lua_package_path '$::MOTAN_P_ROOT/?.lua;$::MOTAN_P_ROOT/?/init.lua;./?.lua;/?.lua;/?/init.lua';"
--- stream_server_config
    preread_by_lua_block {
            local test_data = require "t.lib.data"
            local data = test_data.get_data()
            local utils = require "motan.utils"

            local ffi = require "ffi"
            local motan_tools = ffi.load('motan_tools')
            ffi.cdef[[
            int get_request_id_bytes(const char *, char *);
            ]]

            local rid_num_str = ffi.new("const char *", data)
            local rid_bytes_arr = ffi.new("char[8]")
            motan_tools.get_request_id_bytes(rid_num_str, rid_bytes_arr)
            local bytes = ffi.string(rid_bytes_arr, 8)


            --local bytes = utils.pack_request_id(data)


            ngx.log(ngx.WARN, table.concat({string.byte(bytes, 1, -1)}, ","))
            ngx.say(table.concat({string.byte(bytes, 1, -1)}, ","))
            --ngx.say("done")
    }
    content_by_lua return;
--- stream_request
72057594037927940
--- stream_response
got the request socket
received: 72057594037927940
1,0,0,0,0,0,0,4
--- no_error_log
[error]
--- timeout: 10
