APP := kbot
REGISTRY ?= ghcr.io/artemkuliniak
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo v1.0.0)-$(shell git rev-parse --short HEAD)


TARGETOS ?= $(shell docker version -f '{{.Server.Os}}' 2>/dev/null || go env GOOS)
TARGETARCH ?= $(shell docker version -f '{{.Server.Arch}}' 2>/dev/null || go env GOARCH)

BINARY = $(APP)$(if $(filter windows,$(TARGETOS)),.exe)
IMAGE_TAG = $(REGISTRY)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)

.PHONY: format lint test get build linux arm macos windows \
	image image-linux image-arm image-macos image-windows push clean

format:
	gofmt -s -w ./

lint:
	go vet ./...

test:
	go test -v ./...

get:
	go get

build: format
	CGO_ENABLED=0 GOOS=$(TARGETOS) GOARCH=$(TARGETARCH) go build -v -o $(BINARY) \
		-ldflags "-X=github.com/artemkuliniak/kbot/cmd.appVersion=$(VERSION)"

linux:
	$(MAKE) build TARGETOS=linux TARGETARCH=amd64

arm:
	$(MAKE) build TARGETOS=linux TARGETARCH=arm64

macos:
	$(MAKE) build TARGETOS=darwin TARGETARCH=arm64

windows:
	$(MAKE) build TARGETOS=windows TARGETARCH=amd64

# Image for the host platform (override TARGETOS/TARGETARCH for any other)
image:
	docker build . --platform $(TARGETOS)/$(TARGETARCH) \
		--build-arg VERSION=$(VERSION) -t $(IMAGE_TAG)

# Images for a specific platform
image-linux:
	$(MAKE) image TARGETOS=linux TARGETARCH=amd64

image-arm:
	$(MAKE) image TARGETOS=linux TARGETARCH=arm64

image-macos: image-arm

image-windows:
	$(MAKE) image TARGETOS=windows TARGETARCH=amd64

push:
	docker push $(IMAGE_TAG)

clean:
	rm -f $(APP) $(APP).exe
	-docker rmi $(IMAGE_TAG)
