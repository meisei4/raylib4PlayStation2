# Install for PlayStation 2
- Install last ps2dev ps2sdk follow steps from https://github.com/ps2dev/ps2dev
- clone this repository and execute if you are in Unix like environtment including wsl2:
```
./PlayStation2Build.sh
```

# Samples
- in each sample use make to build
```
% cd samples
% ls
shapes
basic_shapes  collision_area  logo_raylib_anim	mix
% cd logo_raylib_anim
% make clean
rm -f *.elf *.o *.a *.s
% make
/Applications/Xcode.app/Contents/Developer/usr/bin/make raylib.elf
mips64r5900el-ps2-elf-gcc -D_EE -G0 -O2 -Wall -gdwarf-2 -gz -I/usr/local/newps2dev/ps2sdk/ports/include -I../shared_code/  -Wno-strict-aliasing -Wno-conversion-null  -DNO_VU0_VECTORS -DNO_ASM -I/usr/local/newps2dev/ps2sdk/ee/include -I/usr/local/newps2dev/ps2sdk/common/include -I.  -c main.c -o main.o
cc1: warning: command-line option '-Wno-conversion-null' is valid for C++/ObjC++ but not for C
main.c: In function 'updateController':
main.c:39:10: warning: variable 'dpadUpDown' set but not used [-Wunused-but-set-variable]
   39 |     bool dpadUpDown;
      |          ^~~~~~~~~~
main.c:38:10: warning: variable 'dpadDownDown' set but not used [-Wunused-but-set-variable]
   38 |     bool dpadDownDown;
      |          ^~~~~~~~~~~~
main.c:37:10: warning: variable 'dpadRightDown' set but not used [-Wunused-but-set-variable]
   37 |     bool dpadRightDown;
      |          ^~~~~~~~~~~~~
main.c:36:10: warning: variable 'dpadLeftDown' set but not used [-Wunused-but-set-variable]
   36 |     bool dpadLeftDown;
      |          ^~~~~~~~~~~~
mips64r5900el-ps2-elf-g++ -T/usr/local/newps2dev/ps2sdk/ee/startup/linkfile -O2 -o raylib.elf main.o  -L/usr/local/newps2dev/ps2sdk/ee/lib -Wl,-zmax-page-size=128 -s -L/usr/local/newps2dev/ps2sdk/ports/lib -lraylib -lps2gl -lps2stuff -lpad -ldm
```
- Use pcsx2 or your ps2client/ps2sh tools to load elf


Enjoy!!!!

