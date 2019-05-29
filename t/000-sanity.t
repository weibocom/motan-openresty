use Test::Nginx::Socket::Lua::Stream;
use FindBin qw($Bin);
my $root_path = $Bin;
our $MOTAN_P_ROOT=$root_path . "/../lib/";
our $MOTAN_CPATH=$root_path . "/../lib/motan/libs/";
our $MOTAN_DEMO_PATH=$root_path . "/motan-demo/";

$ENV{TEST_NGINX_SERVER_PORT} = 1990;
$ENV{MOTAN_ENV} = "development";
$ENV{APP_ROOT} = $MOTAN_DEMO_PATH;
# $ENV{LUA_PACKAGE_PATH} ||= $MOTAN_DEMO_PATH . "/?.lua;" . $MOTAN_DEMO_PATH . "/?/init.lua;" . $MOTAN_P_ROOT . "/?.lua;" . $MOTAN_P_ROOT . "/?/init.lua;./?.lua;/?.lua;/?/init.lua";
log_level('warn');
#worker_connections(1014);
#master_on();
#workers(2);

repeat_each(2);

# plan tests => repeat_each() * (blocks() * 3 + 3);
use Test::Nginx::Socket::Lua::Stream 'no_plan';

# no_diff();
#no_long_string();
run_tests();

__DATA__

=== TEST 1: motan openresty hello world
--- stream_config eval
    "lua_package_path '$::MOTAN_DEMO_PATH/?.lua;$::MOTAN_DEMO_PATH/?/init.lua;$::MOTAN_P_ROOT/?.lua;$::MOTAN_P_ROOT/?/init.lua;./?.lua;/?.lua;/?/init.lua;;';
    lua_package_cpath '$::MOTAN_CPATH/?.so;;';
    lua_shared_dict motan 20m;
    init_by_lua_block {
        motan = require 'motan'
        motan.init()
    }

    init_worker_by_lua_block {
        motan.init_worker_motan_server()
        motan.init_worker_motan_client()
    }
    "
--- stream_server_config
        lua_socket_pool_size 300;

        content_by_lua_block {
            motan.content_motan_server()
        }
--- http_config eval
    "lua_package_path '$::MOTAN_DEMO_PATH/?.lua;$::MOTAN_DEMO_PATH/?/init.lua;$::MOTAN_P_ROOT/?.lua;$::MOTAN_P_ROOT/?/init.lua;./?.lua;/?.lua;/?/init.lua;;';
    lua_package_cpath '$::MOTAN_CPATH/?.so;;';
    lua_shared_dict motan_http 20m;

    init_by_lua_block {
        motan = require 'motan'
        motan.init()
    }

    init_worker_by_lua_block {
        motan.init_worker_motan_client()
    }"
--- config
    location /motan_client_demo {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local client_map = singletons.client_map
            
            local service_name = 'direct_helloworld_service'
            local service = client_map[service_name]
            local res, err = service:Hello('motan', '_openresty')
            if err ~= nil then
                res = err
            end
            ngx.log(ngx.ERR, "Error idevz Test.\n" .. res)
            ngx.log(ngx.ALERT, "Alert xxxx Test.")
            print("idevz.....")
            ngx.say(res)
        }
    }
--- request
GET /motan_client_demo
--- response_headers
Content-Type: text/plain
--- response_body
motan_openresty_helloworld_test_Hello_ok_motan_openresty
--- no_error_log
[warn]

