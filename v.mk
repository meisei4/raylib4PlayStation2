# TODO: 1. fix refresh thing when compilation database caches in half-finished state before post-process ugliness
# TODO: 2. clean up all the fixdb stuff from a post-process ugly script (find some actual existing tool for this C<->C++ hybrid chaos
# TODO: 3. really test the whole environment agnostic stuff (no hardcoded paths, move stuff like vcl to ps2dev toolchain perhaps)
# TODO: 4. add some ccache stuff?
# TODO: 5. add some sort of screen logging that can be read from the elfs stuff that is defined in this makefile getting overlayed on screen during the elf runs
# TODO: 6. add raylib desktop opengl11 and ps2 builds SIDE BY SIDE like how its done in the /samples/shapes/box/Makefile ./main, ./main_ps2
               # main: main.c
               #	$(CC) -O2 -Wall -Wextra -DPLATFORM_DESKTOP -DPLATFORM_DESKTOP_GLFW -DGRAPHICS_API_OPENGL_11 \
               #	  -I../shared_code/ -I/home/adduser/raylib/src -I/home/adduser/raylib/src/external \
               #	  $(HOST_CFLAGS) main.c -o $@ \
               #	  -L/home/adduser/raylib/src -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -latomic \
               #	  $(HOST_LDFLAGS) $(TRACE_REDIRECT) #?????????????
               #
               #$(PS2RUN): $(EE_BIN)
               #	@echo '#!/usr/bin/env bash' >  $@
               #	@echo "$(PCSX2_BIN) $(PCSX2_FLAGS) -elf ./$(EE_BIN)" >> $@
               #	@chmod +x $@

# TODO: 7. improve clarity about vendored libraries (raylib vs ps2gl, git submodules and symlinking still feels like a hack...)
# TODO: 8. be more utility about the logging to allow for easy visual text parsing during build time or with logs, especially when testing complex stuff later
# TODO: 9. study how to rebuild elfs and get pcsx2 to maybe even hot reload?? (idk, nightmare difficulty level if not impossible)
# TODO: 10. document how this all works, and make it clear that its only really neccessary for overengineered study of C/C++ friendly development
SHELL := /bin/bash
export PATH := $(HOME)/.ccache_wrappers:$(PATH)

.DEFAULT_GOAL := all
SELF_MAKEFILE := $(lastword $(MAKEFILE_LIST))

DB_OUT ?= $(abspath ./compile_commands.json)
DB_RAW := $(DB_OUT).raw
BEAR_BASE   = bear --output $(DB_RAW)
BEAR_APPEND = bear --append --output $(DB_RAW)

COMPILE_DB_TEMP   := $(DB_OUT).new
JOBS   ?= $(shell nproc 2>/dev/null || echo 8)
MAKE_JOBS_FLAG := -j$(JOBS)

PS2GL_LOCAL  ?= $(abspath ./ps2gl)
PS2GL_ROOT    ?= $(PS2GL_LOCAL)
PS2GL_TARGETS ?= all install
PS2GL_REAL    ?= $(PS2GL_ROOT)
# PS2GL_VENDORED ?= $(abspath $(PS2GL_VENDORED_ROOT))
PS2GL_VENDORED ?= $(abspath ../ps2gl)
PS2GL_LINK    ?= $(abspath ./ps2gl-vendored)

RAYLIB_SRC   ?= $(abspath ./raylib/src)
RAYLIB_SRC_INC    := $(abspath $(RAYLIB_SRC))
RAYLIB_FLAGS := PLATFORM=PLATFORM_PLAYSTATION2 GRAPHICS=GRAPHICS_API_OPENGL_11 $(RAYLIB_NOWARN) DEBUG=$(RAYLIB_DEBUG)
#TODO: these files in raylib4Consoles needs to be treated like c++ i think, i.e. g++ comp
RCORE_C_ABS    := $(abspath $(RAYLIB_SRC))/rcore.c
RCORE_PS2C_ABS := $(abspath $(RAYLIB_SRC))/platforms/rcore_playstation2.c

SAMPLES_DIR := $(abspath ./samples)
BIN_DIR     := $(abspath ./bin)

PS2SDK_EE_INC     ?= $(PS2SDK)/ee/include
PS2SDK_COMMON_INC ?= $(PS2SDK)/common/include
PS2SDK_PORTS_INC  ?= $(PS2SDK)/ports/include

PS2_GXX       ?= $(PS2DEV)/ee/bin/mips64r5900el-ps2-elf-g++
PS2_GCC       ?= $(PS2DEV)/ee/bin/mips64r5900el-ps2-elf-gcc
HOST_CC       ?= cc

PCSX2_BIN     ?= pcsx2
PCSX2_FLAGS   ?= -nogui -batch -fastboot -earlyconsolelog -logfile /dev/null

WARN ?= 1
ifeq ($(WARN),0)
  RAYLIB_NOWARN := WARNING_FLAGS=-w
endif

ENABLE_CCACHE ?= 0
PS2_TOOLCHAIN_NAME := mips64r5900el-ps2-elf
PS2_GCC_NAME := $(PS2_TOOLCHAIN_NAME)-gcc
PS2_GXX_NAME := $(PS2_TOOLCHAIN_NAME)-g++
PS2_GCC ?= $(shell command -v $(PS2_GCC_NAME) 2>/dev/null)
PS2_GXX ?= $(shell command -v $(PS2_GXX_NAME) 2>/dev/null)
ifeq ($(ENABLE_CCACHE),1)
  CCACHE_BIN := $(shell command -v ccache 2>/dev/null)
  ifneq ($(CCACHE_BIN),)
    PS2_GCC := $(CCACHE_BIN) $(PS2_GCC)
    PS2_GXX := $(CCACHE_BIN) $(PS2_GXX)
  endif
endif
export CC := $(PS2_GCC)
export CXX := $(PS2_GXX)

.PHONY: setup-ccache
setup-ccache:
	@set -euo pipefail; \
	if [ "$(ENABLE_CCACHE)" != "1" ]; then \
	  echo "ccache disabled (ENABLE_CCACHE=0). Skipping wrapper setup."; exit 0; \
	fi; \
	if ! command -v ccache >/dev/null 2>&1; then \
	  echo "ccache not found in PATH. Install it or set ENABLE_CCACHE=0."; exit 0; \
	fi; \
	mkdir -p "$(HOME)/.ccache_wrappers"; \
	for t in gcc g++; do \
	  ln -sf "$$(command -v ccache)" "$(HOME)/.ccache_wrappers/$(PS2_TOOLCHAIN_NAME)-$$t"; \
	done; \
	echo "Wrappers ready in $$HOME/.ccache_wrappers (gcc/g++)."

ifeq ($(ENABLE_CCACHE),1)
all: setup-ccache
endif

PS2GL_DEBUG  ?= 0
ifdef DEBUG
  PS2GL_DEBUG := $(DEBUG)
endif

.PHONY: _build_stack all with-vendored-ps2gl fixdb print samples clean-samples clean

_build_stack:
	@echo "---------------------------0-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(PS2GL_ROOT)"
	$(BEAR_BASE) -- $(MAKE) $(MAKE_JOBS_FLAG) -C $(PS2GL_ROOT) $(PS2GL_TARGETS) DEBUG=$(PS2GL_DEBUG)
	@echo "---------------------------1-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(RAYLIB_SRC)"
	$(BEAR_APPEND) -- $(MAKE) $(MAKE_JOBS_FLAG) -C $(RAYLIB_SRC) all $(RAYLIB_FLAGS)
	@echo "---------------------------2-----------------------------------"
	@echo "INSTALLLINGGGGGGGG: $(RAYLIB_SRC)"
	$(BEAR_APPEND) -- $(MAKE) $(MAKE_JOBS_FLAG) -C $(RAYLIB_SRC) install $(RAYLIB_FLAGS)
	@echo "---------------------------3-----------------------------------"
	@echo "MAAAAKINNNNNNNNNNG: $(SAMPLES_DIR) into $(BIN_DIR)"
	mkdir -p $(BIN_DIR)
	find $(SAMPLES_DIR) -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname $$mf); echo "==> make -C $$dir"; \
		$(BEAR_APPEND) -- $(MAKE) -C $$dir || exit $$?; \
	done; \
	find $(SAMPLES_DIR) -type f -name raylib.elf -print0 \
	| while IFS= read -r -d '' elf; do \
		dir=$$(dirname $$elf); name=$$(basename $$dir); abs=$$(readlink -f $$elf); \
		out=$(BIN_DIR)/$$name; echo "==> writing $$out -> $$abs"; \
		printf '#!/usr/bin/env bash\n%s %s -elf %s "$$@"\n' \
			$(PCSX2_BIN) '$(PCSX2_FLAGS)' $$abs > $$out; \
		chmod +x $$out; \
	done
	@$(MAKE) -f $(SELF_MAKEFILE) fixdb PS2GL_REAL=$(PS2GL_ROOT)

all: export PS2GL_ROOT := $(PS2GL_LOCAL)
all: export PS2GL_TARGETS := all install
all: export PS2GL_REAL := $(PS2GL_LOCAL)
all: _build_stack fixdb
	@echo "--------------------------DONE---------------------------------"

with-vendored-ps2gl: export PS2GL_ROOT := $(PS2GL_VENDORED)
with-vendored-ps2gl: export PS2GL_TARGETS := clean all install
with-vendored-ps2gl: export PS2GL_REAL := $(PS2GL_VENDORED)
with-vendored-ps2gl:
	@rm -vf $(DB_OUT) $(DB_RAW)
	@$(MAKE) -f $(SELF_MAKEFILE) _build_stack PS2GL_ROOT=$(PS2GL_ROOT) PS2GL_TARGETS="$(PS2GL_TARGETS)"
	@$(MAKE) -f $(SELF_MAKEFILE) fixdb PS2GL_REAL=$(PS2GL_REAL)
	@echo "--------------------------DONE---------------------------------"

.NOTPARALLEL: fixdb
fixdb:
	@set -eu
	ln -sfn $(PS2GL_REAL) $(PS2GL_LINK)
	awk -v PS2_GXX='$(PS2_GXX)' -v PS2_GCC='$(PS2_GCC)' -v HOST_CC='$(HOST_CC)' \
	    -v PS2GL_REAL='$(PS2GL_REAL)' -v PS2GL_LINK='$(PS2GL_LINK)' \
	    -v RCORE_C='$(RCORE_C_ABS)' -v RCORE_PS2C='$(RCORE_PS2C_ABS)' \
	    -v EEINC='$(PS2SDK_EE_INC)' -v COMINC='$(PS2SDK_COMMON_INC)' -v PINC='$(PS2SDK_PORTS_INC)' -v RINC='$(RAYLIB_SRC_INC)' \
	'BEGIN{ depth=0; inobj=0; first=1; have_rcore=0; rcore_buf=""; printf "[\n" } \
	 function base(s){ sub(/^.*\//,"",s); return s } \
	 function parse_driver(lines, n,    i,j,b,e,drv,idx){ \
	   b=e=idx=0; drv=""; \
	   for(i=1;i<=n;i++){ \
	     if(lines[i] ~ /"arguments"[ \t]*:[ \t]*\[/){ \
	       b=i; for(j=i+1;j<=n;j++){ if(lines[j] ~ /\]/){ e=j; break } } \
	       for(j=i+1;j<e;j++){ if(match(lines[j], /"[^"]+"/)){ drv=substr(lines[j],RSTART+1,RLENGTH-2); idx=j; break } } \
	       break; \
	     } \
	   } \
	   ARGB=b; ARGE=e; ARGI=idx; return drv; \
	 } \
	 function maybe_inject_lang_std(lines, n,    k,hasxpair,hasxcxx,hasstd,indent,i,s){ \
	   hasxpair=hasxcxx=hasstd=0; \
	   if(ARGB>0 && ARGE>0) for(k=ARGB+1;k<ARGE;k++){ \
	     if(lines[k] ~ /"-x"[ \t]*,/) hasxpair=1; \
	     if(lines[k] ~ /"c\\+\\+"[ \t]*,/) if(!hasxpair && k>ARGB+1) hasxpair=1; \
	     if(lines[k] ~ /"-xc\\+\\+"/) hasxcxx=1; \
	     if(lines[k] ~ /"(--)?std=[^"]+"/) hasstd=1; \
	   } \
	   need_lang=!(hasxpair||hasxcxx); need_std=!hasstd; \
	   if(!(need_lang||need_std)) return n; \
	   indent=""; if(ARGI>0 && match(lines[ARGI],/^[ \t]+/)) indent=substr(lines[ARGI],RSTART,RLENGTH); \
	   s=""; for(i=1;i<=n;i++){ \
	     s=s lines[i] ORS; \
	     if(i==ARGI){ \
	       if(need_lang){ s=s indent "\"-x\"," ORS indent "\"c++\"," ORS } \
	       if(need_std){  s=s indent "\"-std=gnu++17\"," ORS } \
	     } \
	   } \
	   n=split(s, lines, "\n"); return n; \
	 } \
	 function maybe_inject_lang_std_c(lines, n,    k,hasxpair,hasxc,hasstd,indent,i,s){ \
	   hasxpair=hasxc=hasstd=0; \
	   if(ARGB>0 && ARGE>0) for(k=ARGB+1;k<ARGE;k++){ \
	     if(lines[k] ~ /"-x"[ \t]*,/) hasxpair=1; \
	     if(lines[k] ~ /"c"[ \t]*,/) if(!hasxpair && k>ARGB+1) hasxpair=1; \
	     if(lines[k] ~ /"-xc"/) hasxc=1; \
	     if(lines[k] ~ /"(--)?std=[^"]+"/) hasstd=1; \
	   } \
	   need_lang=!(hasxpair||hasxc); need_std=!hasstd; \
	   if(!(need_lang||need_std)) return n; \
	   indent=""; if(ARGI>0 && match(lines[ARGI],/^[ \t]+/)) indent=substr(lines[ARGI],RSTART,RLENGTH); \
	   s=""; for(i=1;i<=n;i++){ \
	     s=s lines[i] ORS; \
	     if(i==ARGI){ \
	       if(need_lang){ s=s indent "\"-x\"," ORS indent "\"c\"," ORS } \
	       if(need_std){  s=s indent "\"-std=gnu99\"," ORS } \
	     } \
	   } \
	   n=split(s, lines, "\n"); return n; \
	 } \
	 function add_forced_includes(lines,n,   i,ins,inject_after,s){ \
       ins = "\"-I" RINC "\"," ORS \
             "\"-I" PINC "\"," ORS \
             "\"-I" EEINC "\"," ORS \
             "\"-I" COMINC "\"," ORS \
             "\"-include\"," ORS "\"raylib.h\"," ORS \
             "\"-include\"," ORS "\"raymath.h\"," ORS; \
       inject_after = (ARGI>0 ? ARGI : ARGB);  \
       s=""; \
       for(i=1;i<=n;i++){ \
         s=s lines[i] ORS; \
         if(i==inject_after){ s=s ins } \
       } \
       n=split(s, lines, "\n"); return n; \
     } \
	 function get_file_path(obj,   m){ if(match(obj, /"file"[ \t]*:[ \t]*"([^"]+)"/, m)) return m[1]; return "" } \
	 { \
	   if(!inobj){ if($$0 ~ /^[ \t]*\{/ && depth==0){ inobj=1; depth=1; buf=$$0 ORS } ; next } \
	   buf = buf $$0 ORS; \
	   t=$$0; o=gsub(/\{/,"{",t); t=$$0; c=gsub(/\}/,"}",t); depth += (o-c); \
	   if(depth!=0) next; \
	   obj=buf; \
	   n=split(obj, L, "\n"); \
	   drv=parse_driver(L,n); \
	   if(drv==HOST_CC){ inobj=0; buf=""; depth=0; next } \
	   gsub("\"file\"[ \t]*:[ \t]*\"" PS2GL_REAL "/", "\"file\": \"" PS2GL_LINK "/", obj); \
	   gsub("\"directory\"[ \t]*:[ \t]*\"" PS2GL_REAL "\"", "\"directory\": \"" PS2GL_LINK "\"", obj); \
	   if (obj ~ "\"file\"[ \t]*:[ \t]*\"" RCORE_C "\""){ rcore_buf=obj; have_rcore=1 } \
	   if(drv==PS2_GXX || drv==PS2_GCC){ \
	     file=get_file_path(obj); \
	     if(file==RCORE_C || file==RCORE_PS2C){ \
	       n=maybe_inject_lang_std(L,n); \
	     } else if(file ~ /\/raylib\/src\/.*\.c$$/){ \
	       n=maybe_inject_lang_std_c(L,n); \
	     } else { \
	       n=maybe_inject_lang_std(L,n); \
	     } \
	     n=add_forced_includes(L,n); \
         obj=""; for(i=1;i<=n;i++){ obj = obj L[i]; if(i<n) obj = obj "\n"; } \
	   } \
       sub(/[[:space:]]*,[[:space:]]*$$/, "", obj); \
       if(!first){ print "," } \
       first=0; \
       print obj; \
	   inobj=0; buf=""; depth=0; \
	 } \
	 END{ \
       if(have_rcore==1){ \
         clone=rcore_buf; \
         gsub(/"file"[ \t]*:[ \t]*"[^"]*rcore\.c"/, "\"file\": \"" RCORE_PS2C "\"", clone); \
         gsub(/"rcore\.c"/, "\"" RCORE_PS2C "\"", clone); \
         gsub(/"rcore\.o"/, "\"rcore_playstation2.o\"", clone); \
         n=split(clone, L, "\n"); \
         drv=parse_driver(L,n); \
         if(drv){ n=maybe_inject_lang_std(L,n); n=add_forced_includes(L,n) } \
         clone=""; for(i=1;i<=n;i++){ clone=clone L[i]; if(i<n)clone=clone "\n"; } \
         gsub(/[[:space:]]+$$/, "", clone); \
         sub(/[[:space:]]*,[[:space:]]*$$/, "", clone); \
         if (!first) printf(",\n"); \
         print clone; \
       } \
       printf "\n]\n"; \
     }' \
	"$(DB_RAW)" > "$(COMPILE_DB_TEMP)"
	@sed -i 's/"command": *"ccache /"command": "/g' "$(COMPILE_DB_TEMP)"
	@jq --indent 4 . "$(COMPILE_DB_TEMP)" > "$(DB_OUT)"
	@rm -f "$(COMPILE_DB_TEMP)"; echo "Updated: $(DB_OUT) (minified if jq present)"

print:
	@echo "PROJECT_ABS     = $(PROJECT_ABS)"
	@echo "DB_OUT          = $(DB_OUT)"
	@echo "PS2GL_LOCAL     = $(PS2GL_LOCAL)"
	@echo "PS2GL_VENDORED    = $(PS2GL_VENDORED)"
	@echo "RAYLIB_SRC      = $(RAYLIB_SRC)"
	@echo "SAMPLES_DIR     = $(SAMPLES_DIR)"
	@echo "BIN_DIR         = $(BIN_DIR)"
	@echo "PCSX2_BIN       = $(PCSX2_BIN)"

samples:
	@echo "MAAAAKINNNNNNNNNNG: $(SAMPLES_DIR) into $(BIN_DIR)"
	mkdir -p $(BIN_DIR)
	find $(SAMPLES_DIR) -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname $$mf); echo "==> make -C $$dir"; \
		$(MAKE) -C $$dir || exit $$?; \
	done; \
	find $(SAMPLES_DIR) -type f -name raylib.elf -print0 \
	| while IFS= read -r -d '' elf; do \
		dir=$$(dirname $$elf); name=$$(basename $$dir); abs=$$(readlink -f $$elf); \
		out=$(BIN_DIR)/$$name; echo "==> writing $$out -> $$abs"; \
		printf '#!/usr/bin/env bash\n%s %s -elf %s "$$@"\n' \
			$(PCSX2_BIN) '$(PCSX2_FLAGS)' $$abs > $$out; \
		chmod +x $$out; \
	done
	@echo "--------------------------DONE---------------------------------"

clean-samples:
	@echo "CLEANNNNNNNNNNNING: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	@rm -rf $(BIN_DIR)
	@find $(SAMPLES_DIR) -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname $$mf); echo "==> clean $$dir"; \
		$(MAKE) -C $$dir clean || true; \
	done
	@echo "CLEANNNNNNNEDDDDDD: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	@echo "--------------------------DONE---------------------------------"

clean:
	@rm -vf $(DB_OUT) $(DB_RAW)
	@echo "---------------------------0-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(PS2GL_LOCAL)"
	@$(MAKE) -C $(PS2GL_LOCAL) clean
	@echo "CLEANNNNNNNEDDDDDD: $(PS2GL_LOCAL)"
	@echo "---------------------------1-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(PS2GL_VENDORED)"
	@if [ -d $(PS2GL_VENDORED) ]; then \
		$(MAKE) -C $(PS2GL_VENDORED) clean; \
	else \
		echo "skip: $(PS2GL_VENDORED) not found"; \
	fi
	@echo "CLEANNNNNNNEDDDDDD: $(PS2GL_VENDORED)"
	@echo "---------------------------2-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(RAYLIB_SRC)"
	@$(MAKE) -C $(RAYLIB_SRC) clean
	@echo "CLEANNNNNNNEDDDDDD: $(RAYLIB_SRC)"
	@echo "---------------------------3-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	@rm -rf $(BIN_DIR)
	@find $(SAMPLES_DIR) -type f -name Makefile -print0 \
	| while IFS= read -r -d '' mf; do \
		dir=$$(dirname $$mf); echo "==> clean $$dir"; \
		$(MAKE) -C $$dir clean || true; \
	done
	@echo "CLEANNNNNNNEDDDDDD: $(BIN_DIR) ANNNNNNNNNND $(SAMPLES_DIR)"
	@echo "--------------------------DONE---------------------------------"
