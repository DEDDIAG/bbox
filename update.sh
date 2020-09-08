#!/bin/bash
set -e

if [[ -z ${BBOX_PATH} ]]; then
    echo "BBOX_PATH not set"
    exit 1
fi

#
# check repo on changes
#

hash_before=$(cd ${BBOX_PATH} && git rev-parse HEAD)
git -C ${BBOX_PATH} pull
hash_after=$(cd ${BBOX_PATH} && git rev-parse HEAD)

#
# run install.sh and pull new container, if there are changes in repo
# restart system after successfully update
#

if [ "${hash_after}" != "${hash_before}" ]
then
    cd ${BBOX_PATH} && docker-compose pull
    cd ${BBOX_PATH} && sh ${BBOX_PATH}/install.sh
    sudo /sbin/shutdown -r +1
fi
