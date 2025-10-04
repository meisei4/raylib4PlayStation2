TODO: clean this up to be all just in a Makefile and clear concise about its purpose.
make WARN=0 DEBUG=1
(or)
make with-custom-ps2gl WARN=0 DEBUG=1

./comp_db_fixup.sh
(then)
./db_prim.sh


also TODO:

```bash
#!/usr/bin/env bash
set -euo pipefail

scan_repo() {  # $1=dir $2=indent
  local d="${1:-.}" ind="${2:-}"
  git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local name branch head desc dirty
  name="$(basename "$(git -C "$d" rev-parse --show-toplevel)")"
  branch="$(git -C "$d" symbolic-ref --quiet --short HEAD 2>/dev/null || echo '(detached)')"
  head="$(git -C "$d" rev-parse --short HEAD)"
  desc="$(git -C "$d" describe --always --dirty --tags 2>/dev/null || git -C "$d" describe --always --dirty 2>/dev/null || echo "$head")"
  git -C "$d" diff --quiet --ignore-submodules && dirty=clean || dirty=dirty

  echo "${ind}${name} @ ${branch} ${head} (${desc}) ${dirty}"
  echo "${ind}remotes:"
  git -C "$d" remote -v | sort -u | sed "s/^/${ind}  /"
  echo "${ind}local branches:"
  git -C "$d" for-each-ref \
    --format='%(refname:short)  [upstream=%(upstream:short)]  %(objectname:short)  %(contents:subject)' \
    refs/heads | sed "s/^/${ind}  /"

  if [ -f "$d/.gitmodules" ]; then
    mapfile -t submods < <(git -C "$d" config --file "$d/.gitmodules" --get-regexp path | awk '{print $2}')
    ((${#submods[@]})) && echo "${ind}submodules:"
    for sm in "${submods[@]}"; do
      local abspath="$d/$sm"
      if git -C "$abspath" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "${ind}  === $sm ==="
        scan_repo "$abspath" "    ${ind}"
      else
        local sha
        sha="$(git -C "$d" ls-tree HEAD "$sm" 2>/dev/null | awk '{print $3}')"
        echo "${ind}  $sm: (not initialized) recorded at ${sha:-unknown}"
      fi
    done
  fi
}

scan_repo "." ""
```