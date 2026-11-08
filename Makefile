.PHONY: build test run install package clean

build:
	./scripts/build.sh

test:
	swift test
	python3 -m unittest discover -s Tests/ReleaseTests

run: build
	open "build/Swift Quit.app"

install: build
	./scripts/install.sh

package:
	./scripts/package-release.sh "v$$(cat VERSION)"

clean:
	rm -rf build .build
