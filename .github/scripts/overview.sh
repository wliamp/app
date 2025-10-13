#!/bin/bash
set -euo pipefail
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
includes=$(grep -E "include\s*\(" "$settings_file" | sed "s/.*include\s*(//;s/)//" | tr -d "'\"" | tr ',' ' ')
modules=($includes)
declare -A children
for module in "${modules[@]}"; do
  IFS=':' read -ra parts <<< "$module"
  if ((${#parts[@]} == 1)); then
    parent="__root__"
    child="${parts[0]}"
  else
    parent="${parts[*]:0:${#parts[@]}-1}"
    parent="${parent// /:}"
    child="${parts[-1]}"
  fi
  children["$parent"]+="$child "
done
print_tree() {
  local parent="$1"
  local prefix="$2"
  local list=(${children[$parent]:-})
  local count=${#list[@]}

  for ((i=0; i<count; i++)); do
    local child="${list[$i]}"
    local is_last=$((i == count - 1))
    local branch="├─"
    local new_prefix="${prefix}│&nbsp;&nbsp;"
    if ((is_last)); then
      branch="└─"
      new_prefix="${prefix}&nbsp;&nbsp;&nbsp;&nbsp;"
    fi
    local display_path="${parent//:/\/}${parent:+/}${child}"
    echo "${prefix}${branch} [${child}](./${display_path})<br>" >> "$tmpfile"
    print_tree "${parent:+$parent:}$child" "$new_prefix"
  done
}
print_tree "__root__" ""
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
