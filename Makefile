.PHONY: build run dmg install clean

build: ## Build build/LidBlur.app
	./scripts/build.sh

run: build ## Build and launch
	-pkill -x LidBlur
	open build/LidBlur.app

dmg: ## Build build/LidBlur.dmg
	./scripts/dmg.sh

install: build ## Build and copy into /Applications
	-pkill -x LidBlur
	rm -rf /Applications/LidBlur.app
	ditto build/LidBlur.app /Applications/LidBlur.app
	open /Applications/LidBlur.app

clean: ## Remove build output
	rm -rf build .build
