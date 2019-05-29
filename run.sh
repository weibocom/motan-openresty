#!/usr/bin/env bash

### BEGIN ###
# Author: idevz
# Since: 09:30:40 2019/03/02
# Description:       CI Runner
# run          ./run.sh
#
# Environment variables that control this script:
#
### END ###

set -ex
BASE_DIR=$(dirname $(cd $(dirname "$0") && pwd -P)/$(basename "$0"))
MOTAN_SRC_DIR="${BASE_DIR}/lib/motan"
OR_VERSION=${LV:-"openresty-1.15.6.1rc0"}
OR_ROOT="/usr/local/${OR_VERSION}-debug"

OR_IMAGE=${ORIMG:-"zhoujing/idevz-runx-openresty:1.15.6.1rc0"}
CONTAINER_NAME=${CTNAME:-"motan-openresty-dev"}

MESH_TESTHELPER_IMAGE=${MIMG:-"zhoujing/wm-testhelper:1.0.1"}
MESH_CONTAINER_NAME=${MCTNAME:-"mesh-testhelper"}
MEHS_RUN_PATH=${MRUN_PATH:-"${BASE_DIR}/t/weibo-mesh-runpath"}

ZK_TMAGE=${ZKI:-"zookeeper"}
ZK_CONTAINER_NAME=${ZKCTNAME:-"zk"}

test_sanity() {
    # -v ${MOTAN_SRC_DIR}/lib/motan:/usr/local/openresty/site/lualib/motan \
    sudo docker run --rm --name ${CONTAINER_NAME} \
        -e TZ=Asia/Shanghai \
        -v ${BASE_DIR}/t/resty:${OR_ROOT}/site/lualib/resty \
        -v ${MOTAN_SRC_DIR}/libs/libmotan_tools.so:/lib64/libmotan_tools.so \
        -v ${MOTAN_SRC_DIR}/libs/cmotan.so:${OR_ROOT}/lualib/cmotan.so \
        -v ${BASE_DIR}:/runX/run-test \
        -w /runX/run-test \
        ${OR_IMAGE} prove -v ./t
}

prepare_mesh() {
    sudo docker run -d --rm --network host --name ${MESH_CONTAINER_NAME} \
        -v ${MEHS_RUN_PATH}/snapshot:/snapshot \
        -v ${MEHS_RUN_PATH}/mesh-logs:/mesh-logs \
        ${MESH_TESTHELPER_IMAGE}
    sleep 30
    curl 127.0.0.1:8082/200
    sleep 30
}

check_if_stop_container() {
    local containers="${1}"
    if [ ! -z "${containers}" ]; then
        for container in $(echo ${containers//,/ }); do
            sudo docker ps | grep "${container}" &&
                sudo docker stop "${container}"
        done | column -t
    fi
}

do_require() {
    DEPENDENCES='
    https://github.com/pintsized/lua-resty-http/archive/v0.12.tar.gz
    https://github.com/idevz/lua-resty-timer/archive/v0.0.1.tar.gz
    https://github.com/hamishforbes/lua-resty-consul/archive/v0.2.tar.gz
    '
    REQUIRE=${MOTAN_SRC_ROOT}/build/require
    mkdir -p $REQUIRE/src
    mkdir -p $REQUIRE/resty

    for dep in ${DEPENDENCES}; do
        cd $REQUIRE/src
        FILE_NAME=$(echo $dep | sed 's/.*\(lua-resty[^\/]*\)\/.*/\1/g')
        # wget --no-check-certificate $dep -O $FILE_NAME
        curl -fSL $dep -o $FILE_NAME
        tar zxf $FILE_NAME
        cp -fR $FILE_NAME*/lib/resty/* $REQUIRE/resty/
    done
}

test_using_mesh() {
    check_if_stop_container "${ZK_CONTAINER_NAME},${MESH_CONTAINER_NAME}"
    sudo docker run -d --rm --network host --name "${ZK_CONTAINER_NAME}" "${ZK_TMAGE}"
    sleep 30
    prepare_mesh

    # @TODO check zk bug when first time
    # there is no /motan/motan-demo-rpc/com.weibo.HelloWorldService/server node in zk
    # make zk subscrib fail.
    sudo docker stop ${MESH_CONTAINER_NAME}
    sleep 30
    prepare_mesh
    sleep 5

    sudo docker run --rm --network host --name ${CONTAINER_NAME} \
        -e TZ=Asia/Shanghai \
        -v ${BASE_DIR}/t/resty:${OR_ROOT}/site/lualib/resty \
        -v ${MOTAN_SRC_DIR}/libs/libmotan_tools.so:/lib64/libmotan_tools.so \
        -v ${MOTAN_SRC_DIR}/libs/cmotan.so:${OR_ROOT}/lualib/cmotan.so \
        -v ${BASE_DIR}:/runX/run-test \
        -w /runX/run-test \
        ${OR_IMAGE} prove -v ./t/mesh-t/

    curl 127.0.0.1:8082/stop_motan_agent

    sudo docker run --rm --network host --name ${CONTAINER_NAME} \
        -e TZ=Asia/Shanghai \
        -v ${BASE_DIR}/t/resty:${OR_ROOT}/site/lualib/resty \
        -v ${MOTAN_SRC_DIR}/libs/libmotan_tools.so:/lib64/libmotan_tools.so \
        -v ${MOTAN_SRC_DIR}/libs/cmotan.so:${OR_ROOT}/lualib/cmotan.so \
        -v ${BASE_DIR}:/runX/run-test \
        -w /runX/run-test \
        ${OR_IMAGE} prove -v ./t/mesh-t/001-using-mesh-snapshot.t

    check_if_stop_container "${ZK_CONTAINER_NAME},${MESH_CONTAINER_NAME}"
}

case ${1} in
test)
    test_sanity
    test_using_mesh
    ;;
*)
    echo "
Usage:

	./run.sh options [arguments]

The options are:

    ./run.sh test             run tests
"
    ;;
esac
