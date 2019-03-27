#!/bin/bash
# 此脚本为xdevo前端打包

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

set -x
set -e


HubIP="hub.skyinno.com"
HubUser="zhashuyu"
HubPass="chk8c2eYcet#"
BaseDir=$(dirname $0)
ImageName="${HubIP}/facp/vncserver-jmeter"
ImageVer="20190322"

#docker login -u ${HubUser} -p ${HubPass} ${HubIP}

cd ${BaseDir}
nohup python -m SimpleHTTPServer 8000 &
SimpleHTTPServerPid=$!

# docker build -f Dockerfile -t ${ImageName}:${ImageVer} .
docker build -f Dockerfile -t ${ImageName}:${ImageVer} --build-arg CACHEBUST=$(date +%s) . || echo "docker build failed"
# docker push ${ImageName}:${ImageVer}

kill -s 9 ${SimpleHTTPServerPid} > /dev/null 2>&1 || echo
