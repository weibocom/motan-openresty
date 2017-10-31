# Motan-OpenResty
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/weibocom/motan/blob/master/LICENSE)

# Overview
[Motan][motan] is a cross-language remote procedure call(RPC) framework for rapid development of high performance distributed services.

This project is the OpenResty Motan implementation. Provides golang motan server. 

# Quick Start

## Installation

```sh
git clone
```

The quick start gives very basic example of running client and server on the same machine. For the detailed information about using and developing Motan, please jump to [Documents](#documents).
the demo case is in the main/ directory

## Motan server

1. Create serverdemo.ini to config service

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
[motan.service.or_service]
group=idevz-test-static
path=com.weibo.motan.status
registry=consul-test-motan2
version=1
port=1234
host=10.211.55.3
protocol=motan2
serialization=simple
basicRefer=simple_rpc_service
```

2. Write an implementation, create and start RPC Server.

```lua
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local status = {}
    return setmetatable(status, mt)
end

function _M.show_batch(self, opts)
	return "--> Motan openresty----->\n" .. sprint_r(opts)
end

return _M
```

## Motan client

1. Create clientdemo.ini to config service for subscribe

```ini
;config of registries
[motan.registry.consul-test-motan2]
protocol=consul
host=10.211.55.3
port=8500
registryRetryPeriod=30000
registrySessionTimeout=10000
requestTimeout=5000

#conf of refers
[motan.refer.rpc_test]
group=idevz-test-static
path=com.weibo.motan.status
registry=consul-test-motan2
protocol=motan2
serialization=simple
basicRefer=simple_rpc_ref
```

2. Start call

TBD


## Use agent. 

TBD


# Documents

TBD

# License

Motan is released under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

[motan]:https://github.com/weibocom/motan
[consul]:http://www.consul.io