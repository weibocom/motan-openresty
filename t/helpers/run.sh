#!/usr/bin/env bash

### BEGIN ###
# Author: idevz
# Since: 09:40:01 2019/02/21
# Description:       start a mesh proxy for motan-openresty testing
# run          ./run.sh
#
# Environment variables that control this script:
#
### END ###

set -ex
BASE_DIR=${BASE_DIR:-"$(readlink -f "$(dirname "$0")")"}

mesh_image=weibocom/weibo-mesh:0.0.11
mesh_container_name=weibo-mesh

docker stop ${mesh_container_name}
docker rm ${mesh_container_name}

docker run --name ${mesh_container_name} \
    -p 8082:80 \
    -p 9981:9981 \
    -v ${BASE_DIR}/run_mesh:/run_mesh \
    -d ${mesh_image} /weibo-mesh -c /run_mesh/mesh.conf -keep

sleep 2
