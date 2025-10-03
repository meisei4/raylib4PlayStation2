SHELL := /bin/bash

DB_OUT ?= $(abspath ./compile_commands.json)
JOBS ?= $(shell nproc 2>/dev/null || echo 8)

PS2GL_LOCAL ?= $(abspath ./ps2gl)
PS2GL_CUSTOM ?= $(abspath ../ps2gl) #TODO: bad, fix it to have a vendor or something
PS2GL_DEBUG ?= 0

RAYLIB_SRC ?= $(abspath ./raylib/src)
RAYLIB_DEBUG ?= 0         #TODO: havent even used this yet

SAMPLES_DIR := $(abspath ./samples)
BIN_DIR     := $(abspath ./bin)
PCSX2_BIN   ?= pcsx2
PCSX2_FLAGS ?= -nogui -batch -fastboot -earlyconsolelog -logfile /dev/null

BEAR_BASE   = bear --output $(DB_OUT)
BEAR_APPEND = bear --append --output $(DB_OUT)

WARN ?= 1
ifeq ($(WARN),0)
  RAYLIB_NOWARN   := WARNING_FLAGS=-w #IT WORKS!!!!!!!!!!!!!!!!!! dont touch it now
endif

all:
	@echo "---------------------------0-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(PS2GL_LOCAL)"
	$(BEAR_BASE) -- $(MAKE) -j$(JOBS) -C $(PS2GL_LOCAL) all install DEBUG=$(PS2GL_DEBUG) 
	@echo "---------------------------1-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(RAYLIB_SRC)"
	$(BEAR_APPEND) -- $(MAKE) -j$(JOBS) -C $(RAYLIB_SRC) all PLATFORM=PLATFORM_PLAYSTATION2 GRAPHICS=GRAPHICS_API_OPENGL_11 $(RAYLIB_NOWARN) 
	@echo "---------------------------2-----------------------------------"
	@echo "INSTALLLINGGGGGGGG: $(RAYLIB_SRC)"
	$(BEAR_APPEND) -- $(MAKE) -j$(JOBS) -C $(RAYLIB_SRC) install PLATFORM=PLATFORM_PLAYSTATION2 GRAPHICS=GRAPHICS_API_OPENGL_11 $(RAYLIB_NOWARN) 
	@echo "--------------------------3---------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(SAMPLES_DIR) into $(BIN_DIR)"
	mkdir -p $(BIN_DIR)
		find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
		| while IFS= read -r -d '' mf; do \
			dir=$$(dirname "$$mf"); \
			echo "==> make -C $$dir"; \
			$(BEAR_APPEND) -- $(MAKE) -C "$$dir"  || exit $$?; \
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
	@echo "--------------------------DONE---------------------------------"

.PHONY: with-custom-ps2gl
with-custom-ps2gl:
	rm -vf $(DB_OUT)
	@echo "---------------------------0-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(PS2GL_CUSTOM)"
	$(BEAR_BASE) -- $(MAKE) -j$(JOBS) -C $(PS2GL_CUSTOM) clean all install DEBUG=$(PS2GL_DEBUG) 
	@echo "---------------------------1-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(RAYLIB_SRC)"
	$(BEAR_APPEND) -- $(MAKE) -j$(JOBS) -C $(RAYLIB_SRC) all PLATFORM=PLATFORM_PLAYSTATION2 GRAPHICS=GRAPHICS_API_OPENGL_11 $(RAYLIB_NOWARN) 
	@echo "---------------------------2-----------------------------------"
	@echo "INSTALLLINGGGGGGGG: $(RAYLIB_SRC)"
	$(BEAR_APPEND) -- $(MAKE) -j$(JOBS) -C $(RAYLIB_SRC) install PLATFORM=PLATFORM_PLAYSTATION2 GRAPHICS=GRAPHICS_API_OPENGL_11 $(RAYLIB_NOWARN) 
	@echo "---------------------------3-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(SAMPLES_DIR) into $(BIN_DIR)"
	mkdir -p $(BIN_DIR)
		find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
		| while IFS= read -r -d '' mf; do \
			dir=$$(dirname "$$mf"); \
			echo "==> make -C $$dir"; \
			$(BEAR_APPEND) -- $(MAKE) -C "$$dir"   || exit $$?; \
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
	@echo "--------------------------DONE---------------------------------"

clean:
	rm -vf $(DB_OUT)
	@echo "---------------------------0-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(PS2GL_LOCAL)"
	$(MAKE) -C $(PS2GL_LOCAL) clean
	@echo "CLEANNNNNNNEDDDDDD: $(PS2GL_CUSTOM)"
	@echo "---------------------------1-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(PS2GL_CUSTOM)"
	$(MAKE) -C $(PS2GL_CUSTOM) clean
	@echo "CLEANNNNNNNEDDDDDD: $(PS2GL_CUSTOM)"
	@echo "---------------------------2-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(RAYLIB_SRC)"
	$(MAKE) -C $(RAYLIB_SRC) clean
	@echo "CLEANNNNNNNEDDDDDD: $(RAYLIB_SRC)"
	@echo "---------------------------3-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	rm -rf $(BIN_DIR)
	find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname "$$mf"); \
		echo "==> clean $$dir"; \
		$(MAKE) -C "$$dir" clean || true; \
	done
	@echo "CLEANNNNNNNEDDDDDD: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	@echo "--------------------------DONE---------------------------------"

.PHONY: samples clean-samples
samples:
	@echo "MAAAAKINNNNNNNNNNG: $(SAMPLES_DIR) into $(BIN_DIR)"
	mkdir -p $(BIN_DIR)
	find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname "$$mf"); \
		echo "==> make -C $$dir"; \
		$(MAKE) -C "$$dir"   || exit $$?; \
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
	@echo "--------------------------DONE---------------------------------"

clean-samples:
	@echo "CLEANNNNNNNNNNNING: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	rm -rf $(BIN_DIR)
	find "$(SAMPLES_DIR)" -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname "$$mf"); \
		echo "==> clean $$dir"; \
		$(MAKE) -C "$$dir" clean || true; \
	done
	@echo "CLEANNNNNNNEDDDDDD: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	@echo "--------------------------DONE---------------------------------"