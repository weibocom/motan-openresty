-- Copyright (C) idevz (idevz.org)


local singletons = require "motan.singletons"
local APP_ROOT = singletons.var["APP_ROOT"]
local sys_conf = {
        MOTAN_CLIENT_CONF_FILE = "client_conf.ini",
        MOTAN_SERVER_CONF_FILE = "server_conf.ini",
        MOTAN_SERVICE_PROTOCOL = "motan2",
        MOTAN_LUA_SERVICE_PERFIX = "com.weibo.motan.",
        SERVICE_PATH = APP_ROOT .. "motan-service",
    }

return sys_conf