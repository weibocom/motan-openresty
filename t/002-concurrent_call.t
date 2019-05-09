# vim:set ft= ts=4 sw=4 et fdm=marker:

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

=== TEST 1: motan openresty concurrent call
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
            local utils = require 'motan.utils'
            local client_map = singletons.client_map

            local f = function(p1, p2, hk, hv)
                ngx.log(ngx.ERR, "====do call====>" .. table.concat({p1, p2, hk, hv}, "-----"))
                local p1, p2, hk, hv = p1, p2, hk, hv
                local service_name = 'direct_helloworld_service'
                local service = client_map[service_name]
                local service_call_method_name = 'ConcurrentHello'
                local meta_data = {}
                meta_data[hk] = hv
                local res, err = service:call(service_call_method_name, meta_data, p1, p2)
                if err ~= nil then
                    res = err
                end
                return res
            end
            
            local threads = {}
            local run_time = 2
            for a=1, run_time do
                local ok, err = ngx.thread.spawn(f,
                "p1-" .. a, "p2-".. a, 
                "hk-" .. a, "hv-".. a)
                if not ok then
                    ngx.say("failed to spawn writer thread: ", err)
                    return
                end
                threads[a] = ok
            end
            local ok, res_or_err = ngx.thread.wait(threads[run_time])
            if not ok then
                ngx.say("fail to run, err:", res_or_err)
            else
                local check_rs = {}
                for k, v in pairs(res_or_err) do
                    local is_hk = ngx.re.find(k, "hk")
                    if is_hk then
                        table.insert(check_rs, k)
                    end
                end
                ngx.say(sprint_r(check_rs))
                ngx.log(ngx.ERR, sprint_r(check_rs))
            end
            ngx.log(ngx.ERR, "Error idevz Test.\n" .. sprint_r(res_or_err))
            ngx.log(ngx.ALERT, "Alert xxxx Test.")
            print("idevz.....")
        }
    }
--- request
GET /motan_client_demo
--- response_headers
Content-Type: text/plain
--- response_body
{
  "hk-2"
}
--- no_error_log
[warn]