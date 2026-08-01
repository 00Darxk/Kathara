#!/usr/bin/make -f

VERSION=__KATHARA_VERSION__
PACKAGE_VERSION=1
# Fedora release used by a plain `make all`.
# CI overrides it per matrix entry by calling `make docker-build_<release>` directly.
DEFAULT_RELEASE=43

.PHONY: all clean prepare-source prepare-man-pages prepare-bash-completion pack-source build

all: docker-build_$(DEFAULT_RELEASE)

# Pattern target: `make docker-build_43`, `make docker-build_44`, ...
# The Fedora release becomes the %{?dist} tag of the resulting package (1.fc43, 1.fc44), which is what the YUM repository uses to file the package under fedora/<releasever>/<basearch>/.
docker-build_%: clean docker-build-image_%
	docker run --rm -v `pwd`/../../:/opt/kathara $(SET_ARCH) kathara/linux-build-rpm:$* /bin/bash -c \
		"make build && chown -R $(shell id -u):$(shell id -g) Output"

docker-build-image_%:
	cd Docker-Linux-Build && cp Dockerfile_template Dockerfile
	cd Docker-Linux-Build && sed -i -e "s|__RELEASE__|$*|g" Dockerfile
	cd Docker-Linux-Build && docker build $(SET_ARCH) -t kathara/linux-build-rpm:$* .
	cd Docker-Linux-Build && rm Dockerfile

prepare-source:
	cp rpm/kathara.spec ~/rpmbuild/SPECS
	sed -i -e "s|__DATE__|$$(date +'%a %b %d %Y')|g" ~/rpmbuild/SPECS/kathara.spec
	sed -i -e 's/__VERSION__/$(VERSION)/g' ~/rpmbuild/SPECS/kathara.spec
	sed -i -e 's/__PACKAGE_VERSION__/$(PACKAGE_VERSION)/g' ~/rpmbuild/SPECS/kathara.spec
	mkdir -p ~/rpmbuild/SOURCES/kathara-$(VERSION)/src
	cp -r ../../src ~/rpmbuild/SOURCES/kathara-$(VERSION)
	cp kathara.pyinstaller.spec ~/rpmbuild/SOURCES/kathara-$(VERSION)/src/kathara.spec
	mkdir -p ~/rpmbuild/SOURCES/kathara-$(VERSION)/tests
	cp -r ../../tests ~/rpmbuild/SOURCES/kathara-$(VERSION)

prepare-man-pages:
	cd ../../docs && make roff-build
	for man_file in ../../docs/Roff/*; do \
		man_file_dir="man$${man_file: -1}"; \
		[[ -d ../../docs/Roff/$$man_file_dir ]] || mkdir ../../docs/Roff/$$man_file_dir; \
		mv $$man_file ../../docs/Roff/$$man_file_dir; \
	done;
	mkdir -p ~/rpmbuild/SOURCES/kathara-$(VERSION)/manpages
	cp -r ../../docs/Roff/* ~/rpmbuild/SOURCES/kathara-$(VERSION)/manpages
	cd ../../docs && make cleanall

prepare-bash-completion:
	python3 -m pip install -r ../autocompletion/requirements.txt
	python3 ../autocompletion/generate_autocompletion.py ~/rpmbuild/SOURCES/kathara-$(VERSION)/kathara.bash-completion

pack-source: prepare-source prepare-man-pages prepare-bash-completion
	cd ~/rpmbuild/SOURCES/ && tar -zcf kathara-$(VERSION).tar.gz kathara-$(VERSION)
	cd ~/rpmbuild/SOURCES/ && rm -Rf kathara-$(VERSION)

build: pack-source
	rpmbuild -ba ~/rpmbuild/SPECS/kathara.spec
	mkdir -p Output
	cp -r ~/rpmbuild/RPMS/* Output

clean:
	if [ -d Output ]; then \
		rm -rf Output; \
	fi
