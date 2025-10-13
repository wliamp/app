#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob
# shellcheck disable=SC2010
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
  /^[[:space:]]*include[[:space:]]*\(/ {
    match($0, /\(.*\)/)
    args = substr($0, RSTART+1, RLENGTH-2)
    gsub(/'\''|"/, "", args)
    gsub(/,/, " ", args)
    print args
  }
' "$settings_file" | tr '\n' ' ')
if [ -z "$includes" ]; then
  echo "⚠️ No modules found in $settings_file"
  exit 0
fi
declare -A children_map
for module in $includes; do
  IFS=':' read -ra parts <<< "$module"
  parent=""
  for ((i=0; i<${#parts[@]}-1; i++)); do
    parent="${parent:+$parent:}${parts[i]}"
  done
  child="${parts[-1]}"
  key="${parent:-__root__}"
  children_map["$key"]+="$child "
done
print_tree() {
  local prefix="$1"
  local parent="$2"
  local key="${parent:-__root__}"
  # shellcheck disable=SC2206
  local children=(${children_map[$key]:-})
  local count=${#children[@]}
  for ((i=0; i<count; i++)); do
    local child="${children[$i]}"
    local is_last=$(( i == count - 1 ))
    local branch="├─"
    local new_prefix="${prefix}│&nbsp;&nbsp;"
    if (( is_last )); then
      branch="└─"
      new_prefix="${prefix}&nbsp;&nbsp;&nbsp;&nbsp;"
    fi
    local display_path="${parent//:/\/}${parent:+/}${child}"
    echo "${prefix}${branch} [${child}](./${display_path})<br>" >> "$tmpfile"
    print_tree "$new_prefix" "${parent:+$parent:}$child"
  done
}
# shellcheck disable=SC2206
top_level=(${children_map[__root__]:-})
count=${#top_level[@]}
for ((i=0; i<count; i++)); do
  mod="${top_level[$i]}"
  is_last=$(( i == count - 1 ))
  branch="├─"
  prefix="│&nbsp;&nbsp;"
  if (( is_last )); then
    branch="└─"
    prefix="&nbsp;&nbsp;&nbsp;&nbsp;"
  fi
  echo "${branch} [${mod}](./${mod})<br>" >> "$tmpfile"
  print_tree "$prefix" "$mod"
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
