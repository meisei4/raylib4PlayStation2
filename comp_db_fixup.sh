#!/bin/sh

#TODO: fix this and the whole Makefile to be one thing
#  also make it such that this is all environment agnostic -> NOMORE HARDCODE OS PATHS!

set -eu

PROJECT="/home/adduser/raylib4PlayStation2"
DB="$PROJECT/compile_commands.json"
TMP="$PROJECT/.compile_commands.json.tmp"
PS2GL_REAL="/home/adduser/ps2gl"
PS2GL_LINK="$PROJECT/ps2gl-custom"

ln -sfn "$PS2GL_REAL" "$PS2GL_LINK"

awk '
BEGIN{
  GXX="/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-g++"
  HOST="/usr/bin/cc"
  ps2gl_real = "/home/adduser/ps2gl"
  ps2gl_link = "/home/adduser/raylib4PlayStation2/ps2gl-custom"
  proj       = "/home/adduser/raylib4PlayStation2"
  rcore_c    = proj "/raylib/src/rcore.c"
  rcore_ps2c = proj "/raylib/src/platforms/rcore_playstation2.c"

  depth=0; inobj=0; buf=""
  first=1
  have_rcore=0
  rcore_buf=""
  print "["
}
{
  if (!inobj) {
    if ($0 ~ /^[ \t]*\{/ && depth==0) { inobj=1; depth=1; buf=$0 ORS; next }
    else next
  } else {
    buf = buf $0 ORS
    t=$0
    o=gsub(/\{/,"{",t); t=$0
    c=gsub(/\}/,"}",t)
    depth += (o - c)
    if (depth==0) {
      obj = buf

      driver=""
      split(obj, L, "\n")
      args_beg=0; args_end=0
      for(i=1;i<=length(L);i++){
        if(L[i] ~ /"arguments"[ \t]*:[ \t]*\[/){ args_beg=i
          for(j=i+1;j<=length(L);j++){ if(L[j] ~ /\]/){ args_end=j; break } }
          for(j=i+1;j<args_end;j++){ if(match(L[j], /"[^"]+"/)){ driver=substr(L[j],RSTART+1,RLENGTH-2); break } }
          break
        }
      }
      if (driver==HOST) { inobj=0; buf=""; if (!first){}; next }

      gsub(/"file":[ \t]*"\/home\/adduser\/ps2gl\//, "\"file\": \"" ps2gl_link "/", obj)
      gsub(/"directory":[ \t]*"\/home\/adduser\/ps2gl"/, "\"directory\": \"" ps2gl_link "\"", obj)

      if (obj ~ "\"file\"[ \t]*:[ \t]*\"" rcore_c "\"") { have_rcore=1; rcore_buf=obj }

      gsub(/[ \t\r\n]+$/, "", obj); sub(/},?[ \t]*$/, "}", obj)
      if (!first) print ","
      first=0
      print obj

      inobj=0; buf=""
    }
  }
}
END{
  if (have_rcore==1) {
    clone = rcore_buf
    gsub(/"file"[ \t]*:[ \t]*"[^"]*rcore\.c"/, "\"file\": \"" rcore_ps2c "\"", clone)
    gsub(/"rcore\.c"/, "\"" rcore_ps2c "\"", clone)
    gsub(/"rcore\.o"/, "\"rcore_playstation2.o\"", clone)
    print ","
    gsub(/[ \t\r\n]+$/, "", clone); sub(/},?[ \t]*$/, "}", clone)
    print clone
  }
  print "\n]"
}
' "$DB" > "$TMP"

mv -f "$TMP" "$DB"
echo "ok"
