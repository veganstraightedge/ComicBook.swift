# ComicBook.swift
#
# For development, use the script/* commands:
#   script/build · script/test · script/lint · script/format · script/run
#
# This Makefile only covers building-from-source and installing the CLI.

BINARY_NAME = comicbook
INSTALL_DIR = /usr/local/bin

.PHONY: install install-user uninstall uninstall-user clean help

# Build from source and install the CLI system-wide.
install:
	swift build --configuration release
	cp .build/release/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)

# Build from source and install the CLI to ~/.local/bin.
install-user:
	swift build --configuration release
	mkdir -p ~/.local/bin
	cp .build/release/$(BINARY_NAME) ~/.local/bin/$(BINARY_NAME)

uninstall:
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)

uninstall-user:
	rm -f ~/.local/bin/$(BINARY_NAME)

clean:
	swift package clean

help:
	@echo "Dev: use script/build · script/test · script/lint · script/format · script/run"
	@echo "make: install · install-user · uninstall · uninstall-user · clean"
