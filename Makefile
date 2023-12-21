.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

OS_GO_BIN_NAME=go
ifeq ($(shell uname),Windows)
	OS_GO_BIN_NAME=go.exe
endif

OS_GO_OS=$(shell $(OS_GO_BIN_NAME) env GOOS)
# toggle to fake being windows..
#OS_GO_OS=windows

APP_NAME=ldapsvc

BINARY_NAME=ldapsvc
ifeq ($(shell uname),Windows)
	BINARY_NAME=ldapsvc.exe
endif
BINARY_FOLDER=release
VERSION=$(shell cat VERSION)

print: # print make variables
	@echo ""
	@echo "OS_GO_BIN_NAME:    $(OS_GO_BIN_NAME)"
	@echo "OS_GO_OS:          $(OS_GO_OS)"
	@echo ""
	@echo "BINARY_NAME:       $(BINARY_NAME)"
	@echo "VERSION:           $(VERSION)"
	@echo ""

ci-build: # runs all needed make targets in CI. OS independent so can also be run from your laptop.
	@echo ""
	@echo "ci-build called ..."
	$(MAKE) help
	$(MAKE) print
	$(MAKE) test
	$(MAKE) build
	@echo "ci-build finished ...
	@echo ""

build: clean # build  ldapsvc for local system
	$(shell mkdir ${BINARY_FOLDER})
	go build -o ${BINARY_FOLDER}/${BINARY_NAME} ./cmd/main.go

build-linux: clean test # build  ldapsvc for linux system
	$(shell mkdir ${BINARY_FOLDER})
	GOOS=linux go build -o ${BINARY_FOLDER}/${BINARY_NAME} ./cmd/main.go

run: build # build and run ldapsvc
	./${BINARY_FOLDER}/${BINARY_NAME}

run-linux: build-linux # build and run ldapsvc
	./${BINARY_FOLDER}/${BINARY_NAME}

clean: # clean-up binary files
	go clean
	rm -rf coverage.out
	rm -rf ${BINARY_FOLDER}

test: # run tests
	go test -gcflags=all=-l -p=1 ./... -cover -coverprofile ./coverage.out

coverage: $(shell find . -type f -print | grep -v vendor | grep "\.go")
	@go test -cover -coverprofile ./coverage.out ./...

cover: coverage # compute code coverage
	go tool cover -html=./coverage.out

vendor: # pull vendor directories
	go mod vendor

publish:
	#git tag ${VERSION} main
	git push origin ${VERSION}

docker-run: build-linux ## Build the container
	docker build -t $(APP_NAME) -f Dockerfile . 
	docker run -it --rm -p 8080:8080 -v .:/$(APP_NAME) --name="$(APP_NAME)" $(APP_NAME)

first-time: clean vendor test run # run this command to pull all dependencies (this should be run only once)

first-time-linux: clean vendor test build-linux # run this command to pull all dependencies (this should be run only once)