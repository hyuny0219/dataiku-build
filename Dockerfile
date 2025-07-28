FROM almalinux/8-base AS base

## DSS
## NODE_TYPE : api : api node
##           : automation : automation node
##           : design : design node

ARG DSS_VERSION=13.5.5
ARG NODE_TYPE=design

ENV NODE_TYPE=${NODE_TYPE}
ENV DSS_VERSION=${DSS_VERSION}
ENV DSS_HOME=/data/dss_data
ENV DSS_INSTALLDIR=/data/dataiku-dss-${DSS_VERSION}
ENV DSS_PORT=11000

RUN mkdir -p /data/dss_data && \
    useradd -u 5001 dataiku -s /bin/bash

RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y \
    acl \
    expat \
    git \
    nginx \
    unzip \
    zip \
    python3.9 \
    java-17-openjdk-headless.x86_64 \
    policycoreutils \
    policycoreutils-python-utils \
    wget \
    glibc-langpack-en \
    libgfortran \
    libgomp \
    liberation-fonts \
    xorg-x11-fonts-100dpi \
    xorg-x11-fonts-75dpi \
    xorg-x11-fonts-Type1 \
    xorg-x11-utils \
    xorg-x11-fonts-cyrillic \
    xorg-x11-server-Xvfb \
    npm \
    R-core-devel \
    libicu-devel \
    libcurl-devel \
    openssl-devel \
    libxml2-devel \
    gtk3 \
    libXScrnSaver \
    mesa-libgbm \
    libX11-xcb \
    tar && \
    dnf clean all

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh    


RUN mkdir -p /opt/config && \
    echo "DSS_VERSION=${DSS_VERSION}" > /opt/config/config.env && \
    echo "NODE_TYPE=${NODE_TYPE}" >> /opt/config/config.env && \
    echo "DSS_INSTALLDIR=${DSS_INSTALLDIR}" >> /opt/config/config.env && \
    echo "DSS_HOME=${DSS_HOME}" >> /opt/config/config.env && \
    echo "DSS_PORT=${DSS_PORT}" >> /opt/config/config.env

RUN chown -R dataiku:dataiku /data

WORKDIR /data
USER dataiku


#RUN tar xzf dataiku-dss-${DSS_VERSION}.tar.gz && \
#    mv dataiku-dss-${DSS_VERSION}-sha256sums.txt dataiku-dss-${DSS_VERSION} && \
#    cd dataiku-dss-${DSS_VERSION} && \
#    sha256sum -c dataiku-dss-${DSS_VERSION}-sha256sums.txt 2>&1 | grep "OK" && \
#    rm -f dataiku-dss-${DSS_VERSION}.tar.gz

  
#RUN wget https://downloads.dataiku.com/public/dss/${DSS_VERSION}/dataiku-dss-${DSS_VERSION}.tar.gz && \
#    wget https://downloads.dataiku.com/public/dss/${DSS_VERSION}/dataiku-dss-${DSS_VERSION}-sha256sums.txt && \
#    tar xzf dataiku-dss-${DSS_VERSION}.tar.gz && \
#    mv dataiku-dss-${DSS_VERSION}-sha256sums.txt dataiku-dss-${DSS_VERSION} && \
#    cd dataiku-dss-${DSS_VERSION} && \
#    sha256sum -c dataiku-dss-${DSS_VERSION}-sha256sums.txt 2>&1 | grep "OK" && \
#    rm -f dataiku-dss-${DSS_VERSION}.tar.gz

ENV PATH="/usr/bin:$PATH"
ENV PYTHON_BIN=python3.9



#RUN echo "DSS_VERSION=${DSS_VERSION}" > config.env && \
#    echo "NODE_TYPE=${NODE_TYPE}" >> config.env &&\
#    echo "DSS_INSTALLDIR=${DSS_INSTALLDIR}" >> config.env &&\
#    echo "DSS_HOME=${DSS_HOME}" >> config.env &&\
#    echo "DSS_PORT=${DSS_PORT}" >> config.env 

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]


