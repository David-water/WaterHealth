.PHONY: help check project test ui-test ios mac mac-package web clean
help:
	@echo 'check | project | test | ui-test | ios | mac | mac-package | web | clean'
check:
	python3 scripts/check_repository.py
	python3 website/check.py
project:
	python3 scripts/generate_project.py
test:
	zsh scripts/test.sh unit
ui-test:
	zsh scripts/test.sh ui
ios:
	zsh scripts/build_ios.sh simulator
mac:
	zsh scripts/build_macos.sh --build-only
mac-package:
	zsh scripts/build_macos.sh
web:
	python3 -m http.server 4173 --bind 127.0.0.1 --directory website
clean:
	rm -rf .build
