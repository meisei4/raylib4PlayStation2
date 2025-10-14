SHELL := /bin/bash

EE_BIN  = raylib.elf
PS2RUN := main_ps2

EE_OBJS = main.o
EE_LIBS = -lraylib -lps2gl -lps2stuff -lpad -ldma -lps2glut

EE_CFLAGS = -I$(PS2SDK)/ports/include -I../shared_code/
EE_CXXFLAGS := -I$(PS2SDK)/ports/include -I../shared_code/

EE_LDFLAGS  = -s -L$(PS2SDK)/ports/lib

WARNING_CFLAGS   = -Wno-strict-aliasing
WARNING_CXXFLAGS = -Wno-strict-aliasing -Wno-conversion-null

# VU0 code is broken so disable for now
EE_CFLAGS   += $(WARNING_CFLAGS)   -DNO_VU0_VECTORS -DNO_ASM
EE_CXXFLAGS += $(WARNING_CXXFLAGS) -DNO_VU0_VECTORS -DNO_ASM

BIN2S = $(PS2SDK)/bin/bin2s

TRACE ?= 0
LOG   ?= build.log

ifeq ($(TRACE),1)
  EE_CFLAGS    += -H -frecord-gcc-switches
  EE_CXXFLAGS  += -H -frecord-gcc-switches
  HOST_CFLAGS  += -H -frecord-gcc-switches

  EE_LDFLAGS   += -Wl,-Map,$(EE_BIN:.elf=.map) -Wl,--cref -Wl,-t -Wl,--verbose
  HOST_LDFLAGS += -Wl,-Map,main.map          -Wl,--cref -Wl,-t -Wl,--verbose

  TRACE_REDIRECT := 2> >(tee -a $(LOG) >&2)
endif

PCSX2_BIN   ?= pcsx2
PCSX2_FLAGS ?= -nogui -batch -fastboot -earlyconsolelog -logfile /dev/null

define find_raylib_root
$(strip $(firstword $(wildcard $(1)/raylib/src)))
endef

PROJECT_ROOT ?= $(shell git rev-parse --show-toplevel 2>/dev/null)
ifeq ($(PROJECT_ROOT),)
  $(error PROJECT_ROOT not set and not a git repo. Run: make PROJECT_ROOT=/absolute/path HOST=1)
endif

RAYLIB_SRC := $(PROJECT_ROOT)/raylib/src
RAYLIB_DESKTOP_LIB := $(RAYLIB_SRC)/libraylib_desktop.a

DESKTOP ?= 0
ifeq ($(DESKTOP),1)
PROJECT_ROOT ?= $(shell git rev-parse --show-toplevel 2>/dev/null)
ifeq ($(PROJECT_ROOT),)
PROJECT_ROOT := $(abspath $(CURDIR)/../..)
endif
RAYLIB_SRC := $(PROJECT_ROOT)/raylib/src
RAYLIB_DESKTOP_LIB := $(RAYLIB_SRC)/libraylib_desktop.a
HOST_CC ?= $(shell command -v gcc 2>/dev/null || command -v cc || echo cc)

$(RAYLIB_DESKTOP_LIB):
	@cd $(RAYLIB_SRC) && \
	  make PLATFORM=PLATFORM_DESKTOP GRAPHICS=GRAPHICS_API_OPENGL_11 || (echo "raylib/src build failed"; false)
	  cp -f "$(RAYLIB_SRC)/libraylib.a" "$(RAYLIB_DESKTOP_LIB)"; \

main: main.c $(RAYLIB_DESKTOP_LIB)
	$(HOST_CC) -O2 -Wall -Wextra -DPLATFORM_DESKTOP -DPLATFORM_DESKTOP_GLFW -DGRAPHICS_API_OPENGL_11 \
	  -I../shared_code/ -I$(RAYLIB_SRC) -I$(RAYLIB_SRC)/external \
	  $< -o ./main $(RAYLIB_DESKTOP_LIB) \
	  -lGL -lm -lpthread -ldl -lrt -lX11 -latomic

all: $(EE_BIN) main $(PS2RUN)
else
all: $(EE_BIN) $(PS2RUN)
endif

$(PS2RUN): $(EE_BIN)
	@echo '#!/usr/bin/env bash' >  $@
	@echo "$(PCSX2_BIN) $(PCSX2_FLAGS) -elf ./$(EE_BIN)" >> $@
	@chmod +x $@

run: $(EE_BIN)
	ps2client -h 192.168.1.10 execee host:$(EE_BIN)

reset:
	ps2client -h 192.168.1.10 reset

install: $(EE_BIN)
	cp $(EE_BIN) /usr/local/ps2dev/isos

clean:
	rm -vf *.elf *.o *.a *.s main $(PS2RUN) build.summary $(EE_BIN:.elf=.map) main.map $(LOG) $(RAYLIB_DESKTOP_LIB)
	@$(MAKE) -C $(RAYLIB_SRC) clean >/dev/null || true

PS2_RAYLIB   ?= /usr/local/ps2dev/ps2sdk/ports/lib/libraylib.a
PS2_PS2GL    ?= /usr/local/ps2dev/ps2sdk/ports/lib/libps2gl.a
LOCAL_RAYLIB ?= /home/adduser/raylib/src/libraylib.a
LOCAL_PS2GL  ?= /home/adduser/ps2gl/libps2gl.a

SUMMARY_SEARCH_DIRS ?= $(PS2SDK)/ports/lib /home/adduser/raylib/src /home/adduser/ps2gl

SUMMARY_WIDE_SEARCH ?= 0
ifeq ($(SUMMARY_WIDE_SEARCH),1)
  SUMMARY_SEARCH_DIRS += /usr/local/ps2dev
endif

FORCE_build_with_maps:
	@$(MAKE) -B main >/dev/null
	@$(MAKE) -B EE_LDFLAGS="$(EE_LDFLAGS) -Wl,-Map,$(EE_BIN:.elf=.map)" $(EE_BIN) >/dev/null || true
	@$(MAKE) $(PS2RUN) >/dev/null

summary: FORCE_build_with_maps
	@echo "[build_outputs]"
	@for f in $(EE_BIN) main $(PS2RUN); do \
	  if [ -e "$$f" ]; then printf "  %s  " "$$f"; stat -c "%s bytes" "$$f"; else echo "  $$f (missing)"; fi; \
	done
	@echo

	@echo "[where — candidates (bounded scan)]"
	@for d in $(SUMMARY_SEARCH_DIRS); do \
	  test -d "$$d" && find "$$d" -maxdepth 2 -type f \( -name 'libraylib.a' -o -name 'libps2gl.a' \) -print; \
	done | sed 's/^/  /' || true
	@echo

	@echo "[where — actually linked]"
	@if test -s "$(EE_BIN:.elf=.map)"; then \
	  echo "  PS2:"; grep -E '/libraylib\.a|/libps2gl\.a' "$(EE_BIN:.elf=.map)" | sort -u | sed 's/^/    /'; \
	else echo "  PS2: (no map)"; fi
	@if test -s "main.map"; then \
	  echo "  Host:"; grep -E '/libraylib\.a' main.map | sort -u | sed 's/^/    /'; \
	else echo "  Host: (no map)"; fi
	@echo

	@echo "[when — library mtimes]"
	@for L in $(PS2_RAYLIB) $(PS2_PS2GL) $(LOCAL_RAYLIB) $(LOCAL_PS2GL); do \
	  test -r "$$L" && stat -c "  %y  %n" "$$L"; \
	done || true
	@echo

	@echo "[what — file types]"
	@for L in $(PS2_RAYLIB) $(PS2_PS2GL) $(LOCAL_RAYLIB) $(LOCAL_PS2GL); do \
	  test -r "$$L" && file "$$L" | sed 's/^/  /'; \
	done || true
	@echo

summary_verbose: FORCE_build_with_maps
	@echo "[WHERE — wide candidates]"
	@echo # find — lists files matching predicates (AT&T Bell Labs, 1979). Man: https://man7.org/linux/man-pages/man1/find.1.html
	@for d in $(SUMMARY_SEARCH_DIRS); do \
	  test -d "$$d" && find "$$d" -maxdepth 3 -type f \( -name 'libraylib.a' -o -name 'libps2gl.a' \) -print; \
	done | sed 's/^/  /' || true

	@echo "[HOW — archive members used (from PS2 map)]"
	@echo # awk — text processing (Aho/Weinberger/Kernighan, 1977). Man: https://man7.org/linux/man-pages/man1/awk.1.html
	@test -s "$(EE_BIN:.elf=.map)" && awk '/^ \//{p=$$0} /^\(\/.*\.a\)/{print p "  uses  " $$0}' "$(EE_BIN:.elf=.map)" | grep -E 'libraylib\.a|libps2gl\.a' | sed 's/^/  /' | head -80 || echo "  (no PS2 map)"

	@echo "[HOW — headers (PS2, host)]"
	@echo # gcc -H — include tree (GNU, 1987+). Man: https://man7.org/linux/man-pages/man1/gcc.1.html
	@$(if $(wildcard main.c), mips64r5900el-ps2-elf-gcc -H -I$(PS2SDK)/ports/include -I../shared_code/ -I. -c main.c -o /dev/null 2>&1 | sed 's/^/  PS2: /' || true, echo "  PS2: (main.c not found)")
	@$(if $(wildcard main.c), gcc -H -I/home/adduser/raylib/src -I/home/adduser/raylib/src/external -I../shared_code/ -c main.c -o /dev/null 2>&1 | sed 's/^/  Host: /' || true, echo "  Host: (main.c not found)")

	@echo # readelf — ELF inspector (GNU binutils, 1990s). Man: https://man7.org/linux/man-pages/man1/readelf.1.html
	@echo # nm — symbol lister (AT&T Unix, 1970s). Man: https://man7.org/linux/man-pages/man1/nm.1.html
	@tmp_ps2=/tmp/rcore.ps2.o; tmp_host=/tmp/rcore.host.o; \
	ar p "$(PS2_RAYLIB)" rcore.o > $$tmp_ps2 2>/dev/null || true; \
	ar p "$(LOCAL_RAYLIB)" rcore.o > $$tmp_host 2>/dev/null || true; \
	{ test -s $$tmp_ps2  && echo "  PS2 Machine:  $$(mips64r5900el-ps2-elf-readelf -h $$tmp_ps2  | sed -n 's/^ *Machine: *//p')"; } || true; \
	{ test -s $$tmp_host && echo "  Host Machine: $$(readelf -h $$tmp_host | sed -n 's/^ *Machine: *//p')"; } || true; \
	echo "  ps2gl C+(::) count: $$(nm -gC \"$(PS2_PS2GL)\" 2>/dev/null | grep -E '::' | wc -l)"; \
	echo "  raylib C+(::) count: $$(nm -gC \"$(LOCAL_RAYLIB)\" 2>/dev/null | grep -E '::' | wc -l)"

	@echo "[HOW — linker SEARCH_DIR]"
	@echo # ld — linker search dirs (GNU binutils). Man: https://man7.org/linux/man-pages/man1/ld.1.html
	@echo "  PS2:";  mips64r5900el-ps2-elf-ld --verbose 2>/dev/null | sed -n '/SEARCH_DIR/{s/;/;\n/g;p}' | sed 's/^/    /'
	@echo "  Host:"; ld --verbose 2>/dev/null | sed -n '/SEARCH_DIR/{s/;/;\n/g;p}' | sed 's/^/    /'


include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal_cpp