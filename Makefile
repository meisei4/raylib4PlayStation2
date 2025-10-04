SHELL := /bin/bash
.DEFAULT_GOAL := all
SELF_MAKEFILE := $(lastword $(MAKEFILE_LIST))

DB_OUT ?= $(abspath ./compile_commands.json)
JOBS   ?= $(shell nproc 2>/dev/null || echo 8)

PS2GL_LOCAL  ?= $(abspath ./ps2gl)
PS2GL_CUSTOM ?= $(abspath ../ps2gl)
PS2GL_DEBUG  ?= 0

RAYLIB_SRC   ?= $(abspath ./raylib/src)
RAYLIB_DEBUG ?= 0

SAMPLES_DIR := $(abspath ./samples)
BIN_DIR     := $(abspath ./bin)
PCSX2_BIN   ?= pcsx2
PCSX2_FLAGS ?= -nogui -batch -fastboot -earlyconsolelog -logfile /dev/null

BEAR_BASE   = bear --output $(DB_OUT)
BEAR_APPEND = bear --append --output $(DB_OUT)

WARN ?= 1
ifeq ($(WARN),0)
  RAYLIB_NOWARN := WARNING_FLAGS=-w
endif

ifdef DEBUG
  PS2GL_DEBUG  := $(DEBUG)
  RAYLIB_DEBUG := $(DEBUG)
endif

MAKE_JOBS_FLAG := -j$(JOBS)
RAYLIB_FLAGS   := PLATFORM=PLATFORM_PLAYSTATION2 GRAPHICS=GRAPHICS_API_OPENGL_11 $(RAYLIB_NOWARN) DEBUG=$(RAYLIB_DEBUG)

PS2GL_ROOT    ?= $(PS2GL_LOCAL)
PS2GL_TARGETS ?= all install
PS2GL_REAL    ?= $(PS2GL_ROOT)

PS2_GXX       ?= /usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-g++
HOST_CC       ?= /usr/bin/cc

PS2GL_LINK    ?= $(abspath ./ps2gl-custom)
COMPILE_DB_BACKUP := $(DB_OUT).bak
COMPILE_DB_TEMP   := $(DB_OUT).new
RCORE_C_ABS    := $(abspath $(RAYLIB_SRC))/rcore.c
RCORE_PS2C_ABS := $(abspath $(RAYLIB_SRC))/platforms/rcore_playstation2.c

PS2SDK_EE_INC     ?= /usr/local/ps2dev/ps2sdk/ee/include
PS2SDK_COMMON_INC ?= /usr/local/ps2dev/ps2sdk/common/include
PS2SDK_PORTS_INC  ?= /usr/local/ps2dev/ps2sdk/ports/include
RAYLIB_SRC_INC    := $(abspath $(RAYLIB_SRC))/include

.PHONY: all with-custom-ps2gl _build_stack fixdb samples clean clean-samples print

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

with-custom-ps2gl: export PS2GL_ROOT := $(PS2GL_CUSTOM)
with-custom-ps2gl: export PS2GL_TARGETS := clean all install
with-custom-ps2gl: export PS2GL_REAL := $(PS2GL_CUSTOM)
with-custom-ps2gl:
	@rm -vf $(DB_OUT)
	@$(MAKE) -f $(SELF_MAKEFILE) _build_stack PS2GL_ROOT=$(PS2GL_ROOT) PS2GL_TARGETS="$(PS2GL_TARGETS)"
	@$(MAKE) -f $(SELF_MAKEFILE) fixdb PS2GL_REAL=$(PS2GL_REAL)
	@echo "--------------------------DONE---------------------------------"

fixdb:
	@set -eu
	ln -sfn $(PS2GL_REAL) $(PS2GL_LINK)
	cp -f $(DB_OUT) $(COMPILE_DB_BACKUP)
	awk -v PS2_GXX='$(PS2_GXX)' -v HOST_CC='$(HOST_CC)' \
	    -v PS2GL_REAL='$(PS2GL_REAL)' -v PS2GL_LINK='$(PS2GL_LINK)' \
	    -v RCORE_C='$(RCORE_C_ABS)' -v RCORE_PS2C='$(RCORE_PS2C_ABS)' \
	    -v EEINC='$(PS2SDK_EE_INC)' -v COMINC='$(PS2SDK_COMMON_INC)' -v PINC='$(PS2SDK_PORTS_INC)' -v RINC='$(RAYLIB_SRC_INC)' \
	'BEGIN{ depth=0; inobj=0; first=1; have_rcore=0; rcore_buf=""; print "[" } \
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
	   if(drv==PS2_GXX){ n=split(obj,L,"\n"); n=maybe_inject_lang_std(L,n); obj=""; for(i=1;i<=n;i++) obj=obj L[i] ORS } \
	   if(!first) print ","; first=0; print obj; \
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
	     clone=""; for(i=1;i<=n;i++) clone=clone L[i] ORS; \
	     print ","; print clone; \
	   } \
	   print "\n]"; \
	 }' \
	$(DB_OUT) > $(COMPILE_DB_TEMP)
	mv -f $(COMPILE_DB_TEMP) $(DB_OUT)
	@echo "Updated: $(DB_OUT) (backup at $(COMPILE_DB_BACKUP))"

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

clean:
	@rm -vf $(DB_OUT)
	@echo "---------------------------0-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(PS2GL_LOCAL)"
	@$(MAKE) -C $(PS2GL_LOCAL) clean
	@echo "CLEANNNNNNNEDDDDDD: $(PS2GL_LOCAL)"
	@echo "---------------------------1-----------------------------------"
	@echo "CLEANNNNNNNNNNNING: $(PS2GL_CUSTOM)"
	@if [ -d $(PS2GL_CUSTOM) ]; then \
		$(MAKE) -C $(PS2GL_CUSTOM) clean; \
	else \
		echo "skip: $(PS2GL_CUSTOM) not found"; \
	fi
	@echo "CLEANNNNNNNEDDDDDD: $(PS2GL_CUSTOM)"
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

print:
	@echo "PROJECT_ABS     = $(PROJECT_ABS)"
	@echo "DB_OUT          = $(DB_OUT)"
	@echo "PS2GL_LOCAL     = $(PS2GL_LOCAL)"
	@echo "PS2GL_CUSTOM    = $(PS2GL_CUSTOM)"
	@echo "RAYLIB_SRC      = $(RAYLIB_SRC)"
	@echo "SAMPLES_DIR     = $(SAMPLES_DIR)"
	@echo "BIN_DIR         = $(BIN_DIR)"
	@echo "PCSX2_BIN       = $(PCSX2_BIN)"
