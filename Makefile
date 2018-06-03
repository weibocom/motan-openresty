# base conf
PWD=$(realpath ./)
BUILD=$(PWD)/build
$(shell mkdir -p $(BUILD))
SCRIPTS=$(PWD)/scripts

# OpenResty ROOT
OR=openresty
TMP=$(BUILD)/tmp
OR_ROOT := $(shell \
	${OR} -V &> $(TMP) && cat $(TMP) \
	| grep prefix |sed  's/.*prefix\=\(.*\)\/nginx.*/\1/g' \
)
SITE_LUALIB_ROOT=$(OR_ROOT)/site/lualib
$(shell rm $(TMP))

# create app
APP_NAME ?= motan-demo
APP_ROOT ?= $(PWD)/app
PID=$(APP_ROOT)/$(APP_NAME)/logs/nginx.pid

.PHONY: all
all: install create rundev
	@echo "all-ok"

.PHONY: install
install: dependence build
	@echo "install motan success."

.PHONY: dependence
dependence:
	@echo "get motan dependences libs."
	@chmod +x $(SCRIPTS)/dorequire
	@$(SCRIPTS)/dorequire
	@echo "motan dependences libs get done."

.PHONY: create
create:
	@chmod +x $(SCRIPTS)/createapp
	@APP_NAME=$(APP_NAME) APP_ROOT=$(APP_ROOT) $(SCRIPTS)/createapp
	@echo "create app: "$(APP_NAME)" success."

.PHONY: build
build:
	@cp -fR $(PWD)/lib/motan $(SITE_LUALIB_ROOT)
	@mkdir -p $(SITE_LUALIB_ROOT)/resty/
	@cp $(BUILD)/require/resty/* $(SITE_LUALIB_ROOT)/resty/
	@echo "build motan success."
	@rm -rf $(BUILD)
	@echo "build clean success."

.PHONY: clean
clean:
	@rm -rf $(BUILD) $(APP_ROOT)
	@echo "clean success."


.PHONY: run
run:
	@mkdir -p $(APP_ROOT)/$(APP_NAME)/logs
ifeq ($(PID), $(wildcard $(PID)))
	@$(OR) -p $(APP_ROOT)/$(APP_NAME) -s stop
	@echo "stop success."
	@$(OR) -p $(APP_ROOT)/$(APP_NAME)
	@echo "restart success."
else
	@$(OR) -p $(APP_ROOT)/$(APP_NAME)
	@echo "start success."
endif

.PHONY: stop
stop:
	@$(OR) -p $(APP_ROOT)/$(APP_NAME) -s stop
	@echo "stop success."

.PHONY: rundev
rundev:
	@cp -fR $(PWD)/lib/motan $(SITE_LUALIB_ROOT)
	@mkdir -p $(APP_ROOT)/$(APP_NAME)/logs
ifeq ($(PID), $(wildcard $(PID)))
	@MOTAN_ENV=development $(OR) -p $(APP_ROOT)/$(APP_NAME) -s stop
	@echo "dev stop success."
	@MOTAN_ENV=development $(OR) -p $(APP_ROOT)/$(APP_NAME)
	@echo "dev restart success."
else
	@MOTAN_ENV=development $(OR) -p $(APP_ROOT)/$(APP_NAME)
	@echo "dev start success."
endif

.PHONY: stopdev
stopdev:
	@MOTAN_ENV=development $(OR) -p $(APP_ROOT)/$(APP_NAME) -s stop
	@echo "stopdev success."
	