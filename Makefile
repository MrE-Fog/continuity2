# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)

# Used to populate version variable in main package.
VERSION=$(shell git describe --match 'v[0-9]*' --dirty='.m' --always)

GO_LDFLAGS=-ldflags "-X `go list ./version`.Version=$(VERSION)"

.PHONY: clean all fmt vet lint build test binaries setup
.DEFAULT: default
all: AUTHORS clean fmt vet fmt lint build test binaries

AUTHORS: .mailmap .git/HEAD
	 git log --format='%aN <%aE>' | sort -fu > $@

# This only needs to be generated by hand when cutting full releases.
version/version.go:
	./version/version.sh > $@

${PREFIX}/bin/continuity: version/version.go $(shell find . -type f -name '*.go')
	@echo "+ $@"
	@go build  -o $@ ${GO_LDFLAGS}  ${GO_GCFLAGS} ./cmd/continuity

setup:
	@echo "+ $@"
	@go get -u github.com/golang/lint/golint

generate:
	go generate ./...

# Depends on binaries because vet will silently fail if it can't load compiled
# imports
vet: binaries
	@echo "+ $@"
	@go vet ./...

fmt:
	@echo "+ $@"
	@test -z "$$(gofmt -s -l . | grep -v Godeps/_workspace/src/ | grep -v vendor/ | tee /dev/stderr)" || \
		echo "+ please format Go code with 'gofmt -s'"

lint:
	@echo "+ $@"
	@test -z "$$(golint ./... | grep -v Godeps/_workspace/src/ | grep -v vendor/ |tee /dev/stderr)"

build:
	@echo "+ $@"
	@go build -tags "${DOCKER_BUILDTAGS}" -v ${GO_LDFLAGS} ./...

test:
	@echo "+ $@"
	@go test -tags "${DOCKER_BUILDTAGS}" ./...

binaries: ${PREFIX}/bin/continuity
	@echo "+ $@"

clean:
	@echo "+ $@"
	@rm -rf "${PREFIX}/bin/continuity"

