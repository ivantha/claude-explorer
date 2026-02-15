APP_NAME := ClaudeExplorer
SCHEME := $(APP_NAME)
BUILD_DIR := build
DERIVED_DATA := $(BUILD_DIR)/DerivedData
APP_BUNDLE := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app
INSTALL_DIR := /Applications

.PHONY: icons build install uninstall clean

icons:
	python3 scripts/generate_icon.py

build:
	xcodebuild -project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		build

install: build
	@echo "Installing $(APP_NAME).app to $(INSTALL_DIR)..."
	cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Done. $(APP_NAME) is now available in Launchpad and Spotlight."

uninstall:
	@echo "Removing $(APP_NAME).app from $(INSTALL_DIR)..."
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Done."

clean:
	rm -rf $(BUILD_DIR)
