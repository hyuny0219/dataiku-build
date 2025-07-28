#!/bin/bash
set -e
echo "Starting Dataiku DSS entrypoint script..."
echo "Usage: $0 {start}"
echo "Usage: NODE_TYPE : api : api node
                             : automation : automation node
                             : design : design node
     $0 {start} {api|automation:design default: design}
}
docker run <iamge> start design|automation|api
"

cat <<EOF > /data/config.env
DSS_VERSION=${DSS_VERSION}
NODE_TYPE=${NODE_TYPE}
DSS_INSTALLDIR=${DSS_INSTALLDIR}
DSS_HOME=${DSS_HOME}
DSS_PORT=${DSS_PORT}
EOF

source /data/config.env
echo "DSS Version: ${DSS_VERSION}"
echo "DSS_INSTALLDIR: ${DSS_INSTALLDIR}"
echo "DSS_HOME: ${DSS_HOME}"
echo "DSS_PORT: ${DSS_PORT}"

if [ -z $2 ];then
    NODE_TYPE=${NODE_TYPE}
else
    NODE_TYPE=$2
fi

echo "Node Type:::::: ${NODE_TYPE}"
DSS_HOME=${DSS_HOME}
DSS_INSTALLDIR=${DSS_INSTALLDIR}
DSS_VERSION=${DSS_VERSION}
NODE_TYPE=${NODE_TYPE}

start_dss() {
    echo "Starting DSS..."
    echo "DSS_VERSION=${DSS_VERSION} NODE_TYPE=${NODE_TYPE} DSS_HOME=${DSS_HOME} DSS_INSTALLDIR=${DSS_INSTALLDIR}"

    if [ ! -f ${DSS_HOME}/bin/env-default.sh ]; then
            echo "Initialize new data directory"

            ${DSS_INSTALLDIR}/installer.sh -t ${NODE_TYPE} -d ${DSS_HOME} -p ${DSS_PORT}

        if [ "api" != ${NODE_TYPE} ];then
#               ${DSS_HOME}/bin/dssadmin install-R-integration
                ${DSS_HOME}/bin/dssadmin install-graphics-export
        fi

            echo "dku.registration.channel=docker-image" >>${DSS_HOME}/config/dip.properties
            echo "dku.exports.chrome.sandbox=false" >>${DSS_HOME}/config/dip.properties

    elif [ $(bash -c 'source ${DSS_HOME}/bin/env-default.sh && echo "$DKUINSTALLDIR"') != "$DSS_INSTALLDIR" ]; then
            # Upgrade existing data directory
            rm -rf "$DSS_DATADIR"/pyenv
            ${DSS_INSTALLDIR}/installer.sh -t ${NODE_TYPE} -d ${DSS_HOME} -u -y
        if [ "api" != ${NODE_TYPE} ];then
#                ${DSS_HOME}/bin/dssadmin install-R-integration
             ${DSS_HOME}/bin/dssadmin install-graphics-export
            fi
    fi
    echo "license copy........................"
    cp /data/license.json /data/dss_data/config/license.json

    chown -Rh $(id -u):$(id -g) /data/dss_data

    ${DSS_HOME}/bin/dss start
    ${DSS_HOME}/bin/dss status
    tail -f ${DSS_HOME}/run/install.log
}

stop_dss() {
    echo "Stopping DSS..."
    ${DSS_HOME}/bin/dss stop
}

restart_dss() { 
    echo "Restarting DSS..." 
     ${DSS_HOME}/bin/dss restart
     ${DSS_HOME}/bin/dss status
}


health_check() {
    echo "DSS Health Check:"
    if ${DSS_HOME}/bin/dss status | grep -q "RUNNING"; then
        echo "DSS is running"
        exit 0
    else
        echo "DSS is NOT running"
        exit 1
    fi
}
os-check(){
    echo "base os start"
}

case "$1" in
    start)
        start_dss
        ;;
    stop)
        stop_dss
        ;;
    restart)
        restart_dss
        ;;
    health)
        health_check
        ;;
    os-check)
        os-check
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|health}"
        exit 1
        ;;
esac
