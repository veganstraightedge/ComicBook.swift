# ComicBook.swift — common tasks

BINARY_NAME = comicbook
INSTALL_DIR = /usr/local/bin

.PHONY: build release test lint format run install uninstall clean help

build:
	swift build

release:
	swift build --configuration release

test:
	swift test

lint:
	swift format lint --recursive Sources Tests

format:
	swift format --recursive Sources Tests --in-place

run:
	swift run $(BINARY_NAME) $(ARGS)

install: release
	cp .build/release/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)

uninstall:
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)

clean:
	swift package clean

help:
	@echo "make build | release | test | lint | format | run ARGS=... | install | uninstall | clean"
