#!/usr/bin/make -f

VERSION=__KATHARA_VERSION__
DEBIAN_PACKAGE_VERSION=1
OS=ubuntu

.PHONY: docker-build-image prepare-deb-source unpack-deb-source clean-output-folder copy-debian-folder build-man build-deb-unsigned clean venv autocompletion

docker-unsigned_%: clean prepare-deb-source docker-build-image_%
	docker run --rm -v `pwd`/../../:/opt/kathara $(SET_ARCH) kathara/linux-build-deb:$* /bin/bash -c \
	 	"make build-deb-unsigned distro=$* && chown -R $(shell id -u):$(shell id -g) Output"

docker-build-image_%:
	cd Docker-Linux-Build && cp Dockerfile_template Dockerfile
	cd Docker-Linux-Build && sed -i -e "s|__DISTRO__|$*|g" Dockerfile
	cd Docker-Linux-Build && sed -i -e "s|__OS__|$(OS)|g" Dockerfile
	cd Docker-Linux-Build && docker build $(SET_ARCH) -t kathara/linux-build-deb:$* .
	cd Docker-Linux-Build && rm Dockerfile

prepare-deb-source:
	mkdir Output
	cp -r ../../src Output/kathara-$(VERSION)
	cp ./kathara.spec Output/kathara-$(VERSION)/
	cd Output; tar -zcf kathara_$(VERSION).orig.tar.gz kathara-$(VERSION)

unpack-deb-source:
	cd Output; tar -xvf kathara_$(VERSION).orig.tar.gz

clean-output-folder:
	rm -rf Output/kathara-$(VERSION)
	rm -rf Output/kathara_$(VERSION)-$(DEBIAN_PACKAGE_VERSION)$(distro).debian.tar.xz
	rm -rf Output/kathara_$(VERSION)-$(DEBIAN_PACKAGE_VERSION)$(distro).dsc
	rm -rf Output/kathara_$(VERSION)-$(DEBIAN_PACKAGE_VERSION)$(distro)_source.build
	rm -rf Output/kathara_$(VERSION)-$(DEBIAN_PACKAGE_VERSION)$(distro)_source.buildinfo
	rm -rf Output/kathara_$(VERSION)-$(DEBIAN_PACKAGE_VERSION)$(distro)_source.changes

copy-debian-folder:
	cp -r debian Output/kathara-$(VERSION)/
	if [ -z "$$(apt-cache search python3.13 | grep 'python3\.13')" ] ; then sed -i -z -e 's/[ \t]*python3[^,]*,\n//g'  Output/kathara-$(VERSION)/debian/control ; fi
	sed -i -e "s|__DATE__|$$(date -R)|g" Output/kathara-$(VERSION)/debian/changelog
	sed -i -e 's/__DEBIAN_PACKAGE_VERSION__/$(DEBIAN_PACKAGE_VERSION)/g' Output/kathara-$(VERSION)/debian/changelog
	sed -i -e 's/__VERSION__/$(VERSION)/g' Output/kathara-$(VERSION)/debian/changelog
	
venv:
	python3.13 -m venv /root/py-build-env

build-man: copy-debian-folder
	cd ../../docs && make roff-build
	cp -r ../../docs/Roff Output/kathara-$(VERSION)/debian/manpages
	cd ../../docs && make cleanall
	ls Output/kathara-$(VERSION)/debian/manpages/ | awk '{print "debian/manpages/"$$0}' > Output/kathara-$(VERSION)/debian/kathara.manpages

autocompletion:
	/root/py-build-env/bin/pip install --upgrade "setuptools<81.0.0"
	/root/py-build-env/bin/pip install -r ../autocompletion/requirements.txt
	/root/py-build-env/bin/python3 ../autocompletion/generate_autocompletion.py Output/kathara-$(VERSION)/debian/kathara.bash-completion

build-deb-unsigned: venv build-man autocompletion
	sed -i -e 's/__UBUNTU_VERSION__/$(distro)/g' Output/kathara-$(VERSION)/debian/changelog
	cd Output/kathara-$(VERSION); debuild -us -uc

clean:
	if [ -d Output ]; then \
		rm -rf Output; \
	fi
