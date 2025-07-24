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

source config.env
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
            # Initialize new data directory
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

license_dss() {
    echo "Checking DSS license..."

    LICENSE_FILE="$2"
    if [ -z "$LICENSE_FILE" ]; then
        echo "라이선스 JSON 파일 경로를 지정해야 합니다: $0 license -f license.json"
        exit 1
    fi

    if [ ! -f "$LICENSE_FILE" ]; then
        echo "지정한 라이선스 파일이 존재하지 않습니다: $LICENSE_FILE"
        exit 1
    fi

    echo "라이선스 등록 중: $LICENSE_FILE"
    ${DSS_HOME}/bin/dssadmin license set-json "$LICENSE_FILE"

    echo "라이선스 등록 완료!"    
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

install_dss() {
    echo "🔧 Installing DSS..."
    if [ -z "${DSS_VERSION}" ]; then
        echo "DSS version not specified. "
        exit 1
    else
        echo "Installing DSS version: DSS_VERSION=${DSS_VERSION}"
    fi
    if [ -z "${NODE_TYPE}" ]; then
        NODE_TYPE="design"
        echo "DSS version not specified. Using default: ${NODE_TYPE}"
    else
        echo "Installing DSS version:${DSS_VERSION} NODE_TYPE:${NODE_TYPE}"
    fi    
    ${DSS_INSTALLDIR}/installer.sh -t ${NODE_TYPE} -d ${DSS_HOME} -p ${DSS_PORT}
#    ${DSS_HOME}/bin/dssadmin install-R-integration
    ${DSS_HOME}/bin/dssadmin install-graphics-export

    exit 0
}
upgrade_dss() {
    echo "Upgrading DSS..."
    if [ -z "${DSS_VERSION}" ]; then
        echo "DSS version not specified."
        exit 1
    else
        echo "Installing DSS version: DSS_VERSION=${DSS_VERSION}"
    fi
    if [ -z "${NODE_TYPE}" ]; then
        NODE_TYPE="design"
        echo "DSS version not specified. Using default: ${NODE_TYPE}"
    else
        echo "Installing DSS version:${DSS_VERSION} NODE_TYPE:${NODE_TYPE}"
    fi    
    ${DSS_INSTALLDIR}/installer.sh -t ${NODE_TYPE} -d ${DSS_HOME} -u -y
#    ${DSS_HOME}/bin/dssadmin install-R-integration
    ${DSS_HOME}/bin/dssadmin install-graphics-export

    exit 0
    
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
    install)
        install_dss
        start_dss
        ;;  
    upgrade)
        upgrade_dss
        start_dss
        ;; 
    license)
        license_dss "$@"
    ;;
    *)
        echo "Usage: $0 {start|stop|restart|health}"
        exit 1
        ;;
esac


