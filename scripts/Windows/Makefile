#!/usr/bin/make -f

VERSION=__KATHARA_VERSION__
PACKAGE_VERSION=1

ifneq ($(shell uname -m | grep -E "x86_64.*"),) 
    ARCH=x64
else ifeq ($(shell uname -m), amd64) 
    ARCH=x64
else ifneq ($(shell uname -m | grep -E "i.*86"),) 
    ARCH=x86
else ifneq ($(shell uname -m | grep -E "arm.*"),)
	ARCH=arm64
else ifneq ($(shell uname -m | grep -E "aarch.*"),)
	ARCH=arm64
endif

.PHONY: all docker-build-installer docker-build-executable docker-build-image-pyinstaller prepare-source prepare-executable clean-assets clean

all: clean docker-build-installer clean-assets

docker-build-installer: docker-build-executable prepare-executable
	chmod -R a+w Output && umask a+w
	docker run --rm -v `pwd`/Output:/work amake/innosetup installer.iss
	sudo chown -R $(shell id -u):$(shell id -g) Output

docker-build-executable: docker-build-image-pyinstaller prepare-source
	docker run --rm -v `pwd`/Output/src/:/src/ kathara/windows-pyinstaller
	sudo chown -R $(shell id -u):$(shell id -g) Output

docker-build-image-pyinstaller:
	cd Docker-Windows-Build && cp Dockerfile_pyinstaller Dockerfile
	cd Docker-Windows-Build && docker build -t kathara/windows-pyinstaller .
	cd Docker-Windows-Build && rm Dockerfile

prepare-source:
	mkdir -p Output
	cp -r ../../src Output
	cp windows/Assets/kathara.spec Output/src
	cp windows/Assets/app_icon.ico Output/src

prepare-executable: 
	mv Output/src/dist Output/kathara.dist
	rm -rf Output/src
	cp -r windows/Assets Output
	cp 	  windows/installer.iss Output
	cp ../../LICENSE Output
	cd Output && sed -r -i 's|__VERSION__|$(VERSION)|g' installer.iss
	cd Output && sed -r -i 's|..\\..\\..\\src\\(kathara.dist)|\1|g' installer.iss
	cd Output && sed -r -i 's|^;(.*)"__ARCH__"$$|\1"$(ARCH)"|g' installer.iss

clean-assets:
	rm -rf Output/Assets
	rm -rf Output/kathara.dist
	rm  -f Output/installer.iss
	rm  -f Output/LICENSE

clean:
	if [ -d Output ]; then \
		rm -rf Output; \
	fi