EE_BIN = raylib.elf


EE_OBJS = main.o
EE_LIBS =  -lraylib -lps2gl -lps2stuff -lpad -ldma  #-lps2glut
#REPO_ROOT := $(abspath ../..)
#PS2GL_DIR := $(REPO_ROOT)/ps2gl
#RAYLIB_DIR := $(REPO_ROOT)/raylib
#EE_LIBS  := $(PS2GL_DIR)/libps2gl.a $(RAYLIB_DIR)/src/libraylib.a -lpad -ldma -lgs -ldraw -lgraph -lm

EE_CFLAGS = -I$(PS2SDK)/ports/include -I../shared_code/
EE_CXXFLAGS := -I$(PS2SDK)/ports/include -I../shared_code/
#EE_CFLAGS   := -I$(PS2GL_DIR)/include -I$(RAYLIB_DIR)/src -I$(PS2SDK)/ports/include -I../shared_code/
#EE_CXXFLAGS := -I$(PS2GL_DIR)/include -I$(RAYLIB_DIR)/src -I$(PS2SDK)/ports/include -I../shared_code/

EE_LDFLAGS = -s -L$(PS2SDK)/ports/lib


WARNING_FLAGS = -Wno-strict-aliasing -Wno-conversion-null

# VU0 code is broken so disable for now
EE_CFLAGS   += $(WARNING_FLAGS) -DNO_VU0_VECTORS -DNO_ASM
EE_CXXFLAGS += $(WARNING_FLAGS) -DNO_VU0_VECTORS -DNO_ASM

BIN2S = $(PS2SDK)/bin/bin2s

all:
	$(MAKE) $(EE_BIN)

clean:
	rm -f *.elf *.o *.a *.s

run: $(EE_BIN)
	ps2client -h 192.168.1.10 execee host:$(EE_BIN)

reset:
	ps2client -h 192.168.1.10 reset

install:
	cp raylib.elf /usr/local/ps2dev/isos

include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal_cpp