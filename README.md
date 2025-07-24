# dataiku docker build and deploy

## volume mount
docker volume create \
-d local \
-o type=none \
-o device=/mnt/volume-mount/{directory} \
-o o=bind \
dss_design



## docker build

### license file upload
<pre>
	lidense 파일은 docker 실행 시에 volume mount 를 통해서 실행 license.json 
	-v license.json:/data/
</pre>

### base image build
<pre>
	baseImage 디렉토리에 로 이동 후 dataiku version 에 따라 Basic Image build
	Base os : almalinux/8-base 사용
	base os 를 변경이 필요할 경우 각 os 별 필수 설치 패키지 확인 
</pre>

<pre>

	## NODE_TYPE : api : api node
	##           : automation : automation node
	##           : design : design node

	parameters
	ARG DSS_VERSION=13.5.5
	ARG NODE_TYPE=design

	ENV NODE_TYPE=${NODE_TYPE}
	ENV DSS_VERSION=${DSS_VERSION}
	ENV DSS_HOME=/data/dss_data
	ENV DSS_INSTALLDIR=/data/dataiku-dss-${DSS_VERSION}
	ENV DSS_PORT=11000

	dataiku user
	uid : 5001
	gid : 5001



```
docker build --build-arg DSS_VERSION=13.5.5 -t dss-engine:v13.5.5 .
```


### dataiku start
Dockerfile 내의 
<B>docker run 시 "start" parameter 입력</B>

design node install/upgrade/start
```
docker run -id --name dss-design -v dss_design:/data -v ./license.json:/data/license.json:ro -p 8181:11000 dss-engine:13.5.5 start design
```

최초 설치 시에 DSS_HOME 디렉토리에 파일이 있을 경우 설치 에러가 나기때문에 license 파일을 /data 디렉토리에 mount

### version upgrade

```
docker rm -f dss-design
```


```
docker build --build-arg DSS_VERSION=14.0.0 -t dss-engine:14.0.0 .
```

```
docker run -id --name dss-design -v dss_design:/data -v ./license.json:/data/license.json:ro -p 8181:11000 dss-engine:14.0.0 start design
```

entrypoint.sh 파일내에 아래와 같은 코드로 license 파일 복사 처리

<pre>
    echo "license copy........................"
    cp /data/license.json /data/dss_data/config/license.json
</pre>

