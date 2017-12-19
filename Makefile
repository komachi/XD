REPO := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
LOGOS = $(REPO)/contrib/logos
WEBUI_DIR = contrib/webui
WEBUI = ./$(WEBUI_DIR)
GO_ASSETS = $(REPO)/build-assets
DOCROOT = $(WEBUI)/docroot
WEBUI_LOGO = $(DOCROOT)/favicon.png
WEB_FILES = $(DOCROOT)/index.html
WEB_FILES += $(DOCROOT)/xd.min.js
WEB_FILES += $(DOCROOT)/xd.css
WEB_FILES += $(WEBUI_LOGO)
WEBUI_PREFIX = /contrib/webui/docroot

GIT_VERSION ?= $(shell test -e .git && git rev-parse --short HEAD || true)

ifdef GOROOT
	GO = $(GOROOT)/bin/go
endif

GO ?= $(shell which go)

ifeq ($(GOOS),windows)
	XD := $(REPO)/XD.exe
	CLI := $(REPO)/XD-cli.exe
	PREFIX ?= /usr/local # FIXME
else
	XD := $(REPO)/XD
	CLI := $(REPO)/XD-cli
	PREFIX ?= /usr/local
endif

GOPATH := $(REPO)

build: clean $(XD)

$(GO_ASSETS):
	GOPATH=$(GOPATH) $(GO) build -o $(GO_ASSETS) -v github.com/jessevdk/go-assets-builder

assets: $(GO_ASSETS) webui
	$(GO_ASSETS) -p assets $(WEB_FILES) > $(REPO)/src/xd/lib/rpc/assets/assets.go

$(XD): assets
	GOPATH=$(GOPATH) $(GO) build -ldflags "-X xd/lib/version.Git=$(GIT_VERSION) -X xd/lib/rpc/assets.Prefix=$(WEBUI_PREFIX)" -tags webui -o $(XD)

$(CLI): $(XD)
	ln -s XD XD-cli
	chmod 755 XD-cli

test:
	GOPATH=$(GOPATH) $(GO) test -v xd/...

clean: webui-clean go-clean
	rm -f $(CLI)

webui-clean:
	$(MAKE) -C $(WEBUI) clean

go-clean:
	GOPATH=$(GOPATH) $(GO) clean

$(WEBUI_LOGO):
	cp $(LOGOS)/xd_logo.png $(WEBUI_LOGO)

webui: $(WEBUI_LOGO)
	$(MAKE) -C $(WEBUI) clean build

no-webui:
	GOPATH=$(GOPATH) $(GO) build -ldflags "-X xd/lib/version.Git=$(GIT_VERSION) -X xd/lib/rpc/assets.Prefix=$(WEBUI_PREFIX)" -o $(XD)

install: $(XD) $(CLI)
	mkdir -p $(PREFIX)/bin
	install XD $(PREFIX)/bin
	cp -P $(CLI) $(PREFIX)/bin
