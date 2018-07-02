# Motan-OpenResty
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/weibocom/motan/blob/master/LICENSE)


# Overview / October 17 2017
[Motan][motan] is a cross-language remote procedure call(RPC) framework 
for rapid development of high performance distributed services.

This project is the OpenResty Motan implementation. 
Provides OpenResty motan server, motan client.

# Features
- Interactive with mulit language through motan2 protocol,such as Java, PHP.
- Provides cluster support and integrate 
with popular service discovery services like [Consul][consul]. 
- Supports advanced scheduling features like 
weighted load-balance, scheduling cross IDCs, etc.
- Optimization for high load scenarios, 
provides high availability in production environment.

# Quick Start

## Installation

```sh
git clone https://github.com/weibocom/motan-openresty.git motan
```

The quick start gives very basic example of running client and server on the same machine. 
For the detailed information about using and developing Motan, please jump to [Documents](#documents).
the demo case is in the examples/ directory.

## Motan server

1. Create examples/motan-service/sys/MOTAN_SERVER_CONF to config service

```ini
;config of registries
[motan.registry.consul-test-motan2]
protocol=consul
host=10.211.55.3
port=8500
registryRetryPeriod=30000
registrySessionTimeout=10000
requestTimeout=5000

;conf of services
[motan.basicRefer.simple_rpc_ref]
group=yf-api-core
registry=consul-test-motan2
serialization=simple
protocol=motan2
version=0.1
requestTimeout=1000
haStrategy=failover
loadbalance=random
filter=accessLog,metrics
maxClientConnection=10
minClientConnection=1
retries=0
application=whos-agent

[motan.service.or_service]
group=idevz-test-static
path=com.weibo.motan.status
registry=consul-test-motan2
version=1
port=1234
protocol=motan2
serialization=simple
basicRefer=simple_rpc_service
```

2. Write an implementation, create and start RPC Server:
examples/motan-service/status.lua.

```lua
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    return setmetatable({}, mt)
end

function _M.show_batch(self, opts)
    
    return "--> Motan" .. "->not name----->\n" .. sprint_r(opts) .. num

end

return _M
```

## Motan client

1. Create examples/motan-service/sys/MOTAN_CLIENT_CONF 
to config service for subscribe

```ini
;config of registries
[motan.registry.consul-test-motan2]
protocol=consul
host=10.211.55.3
port=8500
registryRetryPeriod=30000
registrySessionTimeout=10000
requestTimeout=5000

;conf of refers
[motan.basicRefer.simple_rpc_ref]
group=yf-api-core
registry=vintage-online
serialization=simple
protocol=motan2
version=0.1
requestTimeout=1000
haStrategy=failover
loadbalance=random
filter=accessLog,metrics
maxClientConnection=10
minClientConnection=1
retries=0
application=whos-agent

[motan.refer.rpc_test]
group=idevz-test-static
path=com.weibo.motan.status
registry=consul-test-motan2
protocol=motan2
serialization=simple
basicRefer=simple_rpc_ref
```

2. Start call

```go
local singletons = require "motan.singletons"
local serialize = require "motan.serialize.simple"
local client_map = singletons.client_map
local client = client_map["rpc_test"]
local res = client:show_batch({name = "idevz"})
print_r("<pre/>")
print_r(serialize.deserialize(res.body))
```

# Documents

* [Wiki](https://github.com/weibocom/motan-go/wiki)
* [Wiki(中文)](https://github.com/weibocom/motan-go/wiki/zh_overview)

# Contributors

* 周晶([@idevz](https://github.com/idevz))
* Ray([@rayzhang0603](https://github.com/rayzhang0603))
* xiaohutuer([@xiaohutuer](https://github.com/xiaohutuer))
* Arthur Guo([@jealone](https://github.com/jealone))
* huzhongx([@huzhongx](https://github.com/huzhongx))
* dingzk([@dingzk](https://github.com/dingzk))

# License

Motan is released under the 
[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

[motan]:https://github.com/weibocom/motan
[consul]:http://www.consul.io
