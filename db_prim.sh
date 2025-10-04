#!/bin/sh
# Minimal compile_commands.json fixer for your PS2 toolchain.
# - Drops host /usr/bin/cc entries
# - Ensures all PS2 g++ entries include: -x c++ and -std=gnu++17
# Hard-coded paths; no env vars; pure awk.

set -eu

IN="/home/adduser/raylib4PlayStation2/compile_commands.json"
BAK="/home/adduser/raylib4PlayStation2/compile_commands.json.bak"
TMP="/home/adduser/raylib4PlayStation2/compile_commands.json.new"

cp -f "$IN" "$BAK"

awk '
BEGIN{
  PS2_GXX="/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-g++"
  HOST_CC="/usr/bin/cc"
  depth=0; inobj=0; buf=""
  first=1
  print "["
}
# Detect start of a top-level object
{
  if (!inobj) {
    if ($0 ~ /^[ \t]*\{/ && depth==0) {
      inobj=1; depth=1; buf=$0 ORS; next
    } else next
  } else {
    buf = buf $0 ORS
    t=$0
    o=gsub(/\{/,"{",t); t=$0
    c=gsub(/\}/,"}",t)
    depth += (o - c)
    if (depth==0) {
      # ----- process one object in buf -----
      n=split(buf, arr, /\n/)
      args_begin=0; args_end=0; driver=""; driver_idx=0

      # locate arguments array and its first element (driver)
      for (i=1;i<=n;i++){
        if (arr[i] ~ /"arguments"[ \t]*:[ \t]*\[/){ args_begin=i
          for (j=i+1;j<=n;j++){
            if (arr[j] ~ /\]/) break
            if (match(arr[j], /"[^\"]+"/)) { driver=substr(arr[j],RSTART+1,RLENGTH-2); driver_idx=j; break }
          }
          for (j=i+1;j<=n;j++){ if (arr[j] ~ /\][ \t]*,?[ \t]*$/){ args_end=j; break } }
          break
        }
      }

      # Drop host cc objects
      keep=1
      if (driver==HOST_CC) keep=0

      if (keep && driver==PS2_GXX && args_begin>0 && args_end>0 && driver_idx>0) {
        # detect presence of -x c++ / -xc++ and -std=
        has_xpair=0; has_xcxx=0; has_std=0
        for (k=args_begin+1; k<args_end; k++){
          if (arr[k] ~ /"[-]{1}x"[ \t]*,/)                      has_xpair=1
          if (arr[k] ~ /"c\+\+"[ \t]*,/)                         has_xpair=(has_xpair?has_xpair: (k>args_begin+1))
          if (arr[k] ~ /"-xc\+\+"/)                               has_xcxx=1
          if (arr[k] ~ /"[-]{1,2}std=[^"]+"/)                     has_std=1
        }
        need_lang = !(has_xpair || has_xcxx)
        need_std  = !has_std

        # figure indentation from driver line (up to first quote)
        indent=""
        if (match(arr[driver_idx], /^[ \t]+/)) indent=substr(arr[driver_idx], RSTART, RLENGTH)

        # rebuild object with optional insertions right after driver line
        buf2=""
        for (i=1;i<=n;i++){
          buf2 = buf2 arr[i] ORS
          if (i==driver_idx){
            if (need_lang){
              buf2 = buf2 indent "\"-x\"," ORS
              buf2 = buf2 indent "\"c++\"," ORS
            }
            if (need_std){
              buf2 = buf2 indent "\"-std=gnu++17\"," ORS
            }
          }
        }
        buf=buf2
      }

      # print object (with commas between objects)
      if (keep){
        gsub(/[ \t\r\n]+$/, "", buf)
        sub(/},?[ \t]*$/, "}", buf)
        if (!first) print ","
        first=0
        print buf
      }

      # reset for next object
      inobj=0; buf=""; depth=0
    }
  }
}
END{
  print "\n]"
}
' "$IN" > "$TMP"

mv -f "$TMP" "$IN"
echo "Updated: $IN (backup at $BAK)"
