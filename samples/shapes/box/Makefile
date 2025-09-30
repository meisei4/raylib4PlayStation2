EE_BIN = raylib.elf


EE_OBJS = main.o
EE_LIBS =  -lraylib -lps2gl -lps2stuff -lpad -ldma  #-lps2glut
REPO_ROOT := $(abspath ../../..)
#PS2GL_DIR := $(REPO_ROOT)/ps2gl
#RAYLIB_DIR := $(REPO_ROOT)/raylib
#EE_LIBS  := $(PS2GL_DIR)/libps2gl.a $(RAYLIB_DIR)/src/libraylib.a -lpad -ldma -lgs -ldraw -lgraph -lm

EE_CFLAGS = -I$(PS2SDK)/ports/include -I../shared_code/
EE_CXXFLAGS := -I$(PS2SDK)/ports/include -I../shared_code/
#EE_CFLAGS   := -I$(PS2GL_DIR)/include -I$(RAYLIB_DIR)/src -I$(PS2SDK)/ports/include -I../shared_code/
#EE_CXXFLAGS := -I$(PS2GL_DIR)/include -I$(RAYLIB_DIR)/src -I$(PS2SDK)/ports/include -I../shared_code/

EE_LDFLAGS = -s -L$(PS2SDK)/ports/lib

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
  EE_LDFLAGS   += -Wl,-Map,$(EE_BIN:.elf=.map) -Wl,--cref -Wl,-t -Wl,--verbose
  HOST_CFLAGS  += -H -frecord-gcc-switches
  HOST_LDFLAGS += -Wl,-Map,main.map -Wl,--cref -Wl,-t -Wl,--verbose
  TRACE_REDIRECT := 2> >(tee -a $(LOG) >&2)
endif

PS2RUN      := main_ps2
PCSX2_BIN   ?= pcsx2
PCSX2_FLAGS ?= -nogui -batch -fastboot -earlyconsolelog -logfile /dev/null

all: $(EE_BIN) main $(PS2RUN)
	@true

clean:
	rm -vf *.elf *.o *.a *.s main $(PS2RUN) build.summary $(EE_BIN:.elf=.map) main.map $(LOG)

main: main.c
	$(CC) -O2 -Wall -Wextra -DPLATFORM_DESKTOP -DPLATFORM_DESKTOP_GLFW -DGRAPHICS_API_OPENGL_11 \
	  -I../shared_code/ -I/home/adduser/raylib/src -I/home/adduser/raylib/src/external \
	  $(HOST_CFLAGS) main.c -o $@ \
	  -L/home/adduser/raylib/src -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -latomic \
	  $(HOST_LDFLAGS) $(TRACE_REDIRECT)

$(PS2RUN): $(EE_BIN)
	@echo '#!/usr/bin/env bash'                    >  $@
	@echo 'pcsx2 $(PCSX2_FLAGS) -elf ./raylib.elf' >> $@
	@chmod +x $@

run: $(EE_BIN)
	ps2client -h 192.168.1.10 execee host:$(EE_BIN)

reset:
	ps2client -h 192.168.1.10 reset

install:
	cp raylib.elf /usr/local/ps2dev/isos

include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal_cpp