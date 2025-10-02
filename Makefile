SHELL := /bin/bash
SAMPLES_DIR := samples
BIN_DIR     := bin
PCSX2_BIN   ?= pcsx2
PCSX2_FLAGS ?= -nogui -batch -fastboot -earlyconsolelog -logfile /dev/null

.PHONY: samples clean-samples

samples:
	mkdir -p $(BIN_DIR)
	find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname "$$mf"); \
		echo "==> make -C $$dir"; \
		$(MAKE) -C "$$dir" || exit $$?; \
	done; \
	find "$(SAMPLES_DIR)" -type f -name 'raylib.elf' -print0 \
	| while IFS= read -r -d '' elf; do \
		dir=$$(dirname "$$elf"); \
		name=$$(basename "$$dir"); \
		abs=$$(readlink -f "$$elf"); \
		out="$(BIN_DIR)/$$name"; \
		echo "==> writing $$out -> $$abs"; \
		printf '#!/usr/bin/env bash\n%s %s -elf %s "$$@"\n' \
			'$(PCSX2_BIN)' '$(PCSX2_FLAGS)' "$$abs" > "$$out"; \
		chmod +x "$$out"; \
	done

clean-samples:
	rm -rf "$(BIN_DIR)"
	find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname "$$mf"); \
		echo "==> clean $$dir"; \
		$(MAKE) -C "$$dir" clean || true; \
	done
