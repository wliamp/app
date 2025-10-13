#!/bin/bash
set -e
settings_file=$(ls | grep -E "settings.gradle(\.kts)?$" || true)
if [ -z "$settings_file" ]; then
  echo "❌ settings.gradle NOT FOUND"
  exit 1
fi
readme="README.md"
tmpfile="structure.tmp"
root_name=$(grep -E "^rootProject.name" "$settings_file" | sed "s/.*['\"]\\(.*\\)['\"].*/\\1/")
root_name=${root_name:-root}
echo "$root_name<br>" > "$tmpfile"
includes=$(awk '
  BEGIN { capture=0 }
  /^[[:space:]]*include[[:space:]]/ {
    capture=1
  }
  capture {
    line = line " " $0
    if ($0 !~ /,|'\''/) capture=0
  }
  END {
    gsub(/include/, "", line)
    print line
  }
' "$settings_file")
modules=$(echo "$includes" | tr -d "'" | tr ',' '\n' | sed '/^\s*$/d')
declare -A tree
while read -r module; do
  module=$(echo "$module" | xargs)
  IFS=':' read -ra parts <<< "$module"
  path=""
  for ((i=0; i<${#parts[@]}; i++)); do
    part="${parts[$i]}"
    path="${path:+$path:}$part"
    if (( i < ${#parts[@]} - 1 )); then
      tree["$path"]+=":${parts[$((i+1))]}"
    fi
  done
done <<< "$modules"
for key in "${!tree[@]}"; do
  IFS=':' read -ra children <<< "${tree[$key]}"
  uniq_children=($(printf "%s\n" "${children[@]}" | sort -u))
  tree["$key"]=":${uniq_children[*]}"
done
print_tree() {
  local prefix="$1"
  local path="$2"
  local depth="$3"
  local children=()
  IFS=':' read -ra raw_children <<< "${tree[$path]}"
  for child in "${raw_children[@]}"; do
    [[ -z "$child" ]] && continue
    children+=("$child")
  done
  local count=${#children[@]}
  for ((i=0; i<count; i++)); do
    local child="${children[$i]}"
    local is_last=$(( i == count - 1 ))
    local branch_symbol="├─"
    local next_prefix="${prefix}│&nbsp;&nbsp;"
    if (( is_last )); then
      branch_symbol="└─"
      next_prefix="${prefix}&nbsp;&nbsp;&nbsp;&nbsp;"
    fi
    local display_path="${path//:/\/}/$child"
    echo "${prefix}${branch_symbol} [${child}](./${display_path})<br>" >> "$tmpfile"
    print_tree "$next_prefix" "${path:+$path:}$child" $((depth + 1))
    if (( is_last && depth == 0 )); then
      echo "│<br>" >> "$tmpfile"
    fi
  done
}
top_level_modules=($(echo "$modules" | awk -F':' '{print $1}' | sort -u))
count=${#top_level_modules[@]}
for ((i=0; i<count; i++)); do
  module="${top_level_modules[$i]}"
  is_last=$(( i == count - 1 ))
  branch_symbol="├─"
  next_prefix="│&nbsp;&nbsp;"
  if (( is_last )); then
    branch_symbol="└─"
    next_prefix="&nbsp;&nbsp;&nbsp;&nbsp;"
  fi
  echo "${branch_symbol} [${module}](./${module})<br>" >> "$tmpfile"
  print_tree "$next_prefix" "$module" 0
  echo "│<br>" >> "$tmpfile"
done
start="<!-- START_STRUCTURE -->"
end="<!-- END_STRUCTURE -->"
content=$(cat "$tmpfile")
if [ ! -f "$readme" ]; then
  echo "# Project Overview" > "$readme"
fi
if grep -q "$start" "$readme" && grep -q "$end" "$readme"; then
  awk -v s="$start" -v e="$end" -v r="$content" '
    $0~s {print; print r; skip=1; next}
    $0~e {skip=0}
    !skip
  ' "$readme" > README.tmp && mv README.tmp "$readme"
else
  echo -e "\n$start\n$content\n$end" >> "$readme"
fi
