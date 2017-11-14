-- Copyright (C) idevz (idevz.org)

local _M = {
    _VERSION = '0.0.1'
}
local setmetatable = setmetatable

if setfenv then                 -- for lua5.1 and luajit
   setfenv(1, _M)
else
   error("both setfenv and _ENV are nil...")
end


-- local mt = { __index = _M}


SEPERATOR_ACCESS_LOG = "|"
COMMA_SEPARATOR = ","
MINUS_SEPARATOR = "-"
PROTOCOL_SEPARATOR = "://"
COLON_SEPARATOR = ":"
PATH_SEPARATOR = "/"
QMARK_SEPARATOR = "?"
REGISTRY_SEPARATOR = "|"
SEMICOLON_SEPARATOR = ""
QUERY_PARAM_SEPARATOR = "&"
EQUAL_SIGN_SEPERATOR = "="
COMMA_SPLIT_PATTERN = [["\\s*[,]+\\s*")]]
REGISTRY_SPLIT_PATTERN = [["\\s*[|]+\\s*")]]
SEMICOLON_SPLIT_PATTERN = [["\\s*[]+\\s*")]]
QUERY_PARAM_PATTERN = [["\\s*[&]+\\s*")]]
EQUAL_SIGN_PATTERN = [["\\s*[=]\\s*")]]
NODE_TYPE_SERVICE = "service"
NODE_TYPE_REFERER = "referer"
SCOPE_NONE = "none"
SCOPE_LOCAL = "local"
SCOPE_REMOTE = "remote"
REGISTRY_PROTOCOL_LOCAL = "local"
REGISTRY_PROTOCOL_DIRECT = "direct"
REGISTRY_PROTOCOL_ZOOKEEPER = "zookeeper"
PROTOCOL_MOTAN = "motan"
PROXY_JDK = "jdk"
PROXY_JAVASSIST = "javassist"
FRAMEWORK_NAME = "motan"
PROTOCOL_SWITCHER_PREFIX = "protocol:"
METHOD_CONFIG_PREFIX = "methodconfig."
MILLS = 1
SECOND_MILLS = 1000
MINUTE_MILLS = 60 * SECOND_MILLS
DEFAULT_VALUE = "default"
DEFAULT_INT_VALUE = 0
DEFAULT_VERSION = "1.0"
DEFAULT_THROWS_EXCEPTION = true
DEFAULT_CHARACTER = "utf-8"
SLOW_COST = 50      --50ms
STATISTIC_PEROID = 30       --30 seconds
ASYNC_SUFFIX = "Async"      --suffix for async call.
APPLICATION_STATISTIC = "statisitic"


-- heartbeat constants start

HEARTBEAT_PERIOD = 500
HEARTBEAT_INTERFACE_NAME = "com.weibo.api.motan.rpc.heartbeat"
HEARTBEAT_METHOD_NAME = "heartbeat"

-- heartbeat constants end


ZOOKEEPER_REGISTRY_NAMESPACE = "/motan"
ZOOKEEPER_REGISTRY_COMMAND = "/command"

REGISTRY_HEARTBEAT_SWITCHER = "feature.configserver.heartbeat"


-- 默认的consistent的hash的数量

DEFAULT_CONSISTENT_HASH_BASE_LOOP = 1000

---------------- motan 2 protocol constants -----------------
M2_GROUP = "M_g"
M2_VERSION = "M_v"
M2_PATH = "M_p"
M2_METHOD = "M_m"
M2_METHOD_DESC = "M_md"
M2_AUTH = "M_a"
M2_SOURCE = "M_s"       --调用方来源标识,等同与application
M2_MODULE = "M_mdu"
M2_PROXY_PROTOCOL = "M_pp"
M2_INFO_SIGN = "M_is"
M2_ERROR = "M_e"
M2_PROCESS_TIME = "M_pt"

---------------- Global CTX Sys Conf -----------------
MOTAN_GCTX_CONF_KEY = "globalcontext"
MOTAN_REGISTRY_PREFIX     = "motan.registry."
MOTAN_BASIC_REFS_PREFIX   = "motan.basicRefer."
MOTAN_BASIC_REF_KEY = "basicRefer"
MOTAN_REFS_PREFIX        = "motan.refer."
MOTAN_BASIC_SERVICES_PREFIX = "motan.basicService."
MOTAN_SERVICES_PREFIX      = "motan.service."

MOTAN_REGISTRY_KEY = "registry"
MOTAN_FILTER_KEY = "filter"

MOTAN_NODETYPE_SERVICE = "service"
MOTAN_NODETYPE_REFERER = "referer"


MOTAN_MAGIC = 0xF1F1;
MOTAN_MSG_TYPE = 0x02;
MOTAN_VERSION_STATUS = 0x08;
MOTAN_SERIALIZE = 0x08;

MOTAN_SERIALIZE_HESSIAN = 0;
MOTAN_SERIALIZE_PB = 1;
MOTAN_SERIALIZE_SIMPLE = 6;

MOTAN_MSG_STATUS_NORMAL = 0;
MOTAN_MSG_STATUS_EXCEPTION = 1;

MOTAN_MSG_TYPE_REQUEST = 0;
MOTAN_MSG_TYPE_RESPONSE = 1;

MOTAN_HEADER_BYTE = 13;
MOTAN_META_SIZE_BYTE = 4;
MOTAN_BODY_SIZE_BYTE = 4;

MOTAN_HEADER_MAGIC_NUM_BYTE = 2
MOTAN_HEADER_MSG_TYPE_BYTE = 1
MOTAN_HEADER_VERSION_STATUS_BYTE = 1
MOTAN_HEADER_SERIALIZE_BYTE = 1
MOTAN_HEADER_REQUEST_ID_BYTE = 8

MOTAN_SIMPLE_TYPE_BYTE = 1
MOTAN_DATA_PACK_INT32_BYTE = 4

MOTAN_LUA_SERVICES_SHARE_KEY = "MOTAN_LUA_SERVICES"
MOTAN_LUA_REFERERS_LRU_KEY = "MOTAN_LUA_REFERERS"
MOTAN_LUA_CLIENTS_LRU_KEY = "MOTAN_LUA_CLIENTS"
MOTAN_LUA_SERVICE_PACKAGE = "MOTAN_LUA_SERVICE_PACKAGE"
MOTAN_LRU_MAX_REFERERS = 100


---------------- protocol constants -----------------
MOTAN_SERIALIZE_ARR = {}
MOTAN_SERIALIZE_ARR[0] = "hessian"
MOTAN_SERIALIZE_ARR[1] = "grpc-pb"
MOTAN_SERIALIZE_ARR[2] = "json"
MOTAN_SERIALIZE_ARR[3] = "msgpack"
MOTAN_SERIALIZE_ARR[6] = "simple"



---------------- consul registry constants -----------------

MOTAN_CONSUL_HEARTBEAT_PERIOD = 5

-- * motan rpc 在consul service中的前缀
MOTAN_CONSUL_SERVICE_MOTAN_PRE = "motanrpc_"
-- * motan协议在consul tag中的前缀
MOTAN_CONSUL_TAG_MOTAN_PROTOCOL = "protocol_"
MOTAN_CONSUL_TAG_MOTAN_URL = "URL_";
-- * motan rpc 在consul中存储command的目录
MOTAN_CONSUL_MOTAN_COMMAND = "motan/command/"
-- * 默认consul agent的ip
MOTAN_CONSUL_DEFAULT_HOST = "127.0.0.1"
-- * 默认consul agent的端口
MOTAN_CONSUL_DEFAULT_PORT = 8500
-- * service 最长存活周期（Time To Live），单位秒。 每个service会注册一个ttl类型的check，在最长TTL秒不发送心跳
-- * 就会将service变为不可用状态。
MOTAN_CONSUL_TTL = 30
-- * HEARTBEAT_TTL的字符串格式
MOTAN_CONSUL_TTL_STR = MOTAN_CONSUL_TTL .. "s"
-- * 心跳周期，取ttl的2/3
MOTAN_CONSUL_HEARTBEAT_CIRCLE = (MOTAN_CONSUL_TTL * 1000 * 2) / 3
-- * 连续检测开关变更的最大次数，超过这个次数就发送一次心跳
MOTAN_CONSUL_MAX_SWITCHER_CHECK_TIMES = 10
-- * 检测开关变更的频率，连续检测MAX_SWITCHER_CHECK_TIMES次必须发送一次心跳。
MOTAN_CONSUL_SWITCHER_CHECK_CIRCLE = MOTAN_CONSUL_HEARTBEAT_CIRCLE / MOTAN_CONSUL_MAX_SWITCHER_CHECK_TIMES
-- * consul服务查询默认间隔时间。单位毫秒
MOTAN_CONSUL_DEFAULT_LOOKUP_INTERVAL = 30000
-- * consul心跳检测开关。
-- @Deprecate
MOTAN_CONSUL_PROCESS_HEARTBEAT_SWITCHER = "feature.consul.heartbeat";
-- * consul block 查询时 block的最长时间,单位，分钟
MOTAN_CONSUL_BLOCK_TIME_MINUTES = 10
-- * consul block 查询时 block的最长时间,单位，秒
MOTAN_CONSUL_BLOCK_TIME_SECONDS = MOTAN_CONSUL_BLOCK_TIME_MINUTES * 60


---------------- motan ext constants -----------------

MOTAN_FILTER_TYPE_CLUSTER = 1
MOTAN_FILTER_TYPE_ENDPOINT = 2

setmetatable(_M, {
    __newindex = 
    function (self, key, ...)
         error('Attempt to write to undeclared variable "' .. key .. '"')
    end,
})

return _M
