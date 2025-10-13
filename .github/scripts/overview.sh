#!/usr/bin/env bash
set -euo pipefail
settings_file="settings.gradle"
readme="README.md"
tmpfile="$(mktemp)"
if [ ! -f "$settings_file" ]; then
  echo "❌ $settings_file NOT FOUND"
  exit 1
fi
root_name=$(grep -E "^rootProject.name" "$settings_file" | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/")
root_name=${root_name:-root}
include_block=$(awk '
  BEGIN {found=0;buf=""}
  /^\s*include/ {
    line=$0
    sub(/^\s*include\s*/, "", line)
    buf=line
    found=1
    next
  }
  found && /^\s+/ {
    buf=buf" "$0
    next
  }
  END {
    if(found) print buf
  }
' "$settings_file")
if [ -z "$include_block" ]; then
  modules_list=""
else
  modules_list=$(printf "%s" "$include_block" \
    | tr ',' '\n' \
    | sed "s/'//g; s/^[ \t]*//; s/[ \t]*$//" \
    | sed '/^$/d')
fi
declare -A children
declare -A seen_child
declare -A exists_node
append_child() {
  parent="$1"
  child="$2"
  key="${parent}|${child}"
  if [ -z "${seen_child[$key]:-}" ]; then
    if [ -z "${children[$parent]:-}" ]; then
      children[$parent]="$child"
    else
      children[$parent]="${children[$parent]}"$'\n'"$child"
    fi
    seen_child[$key]=1
  fi
}
IFS=$'\n'
for module in $modules_list; do
  [ -z "$module" ] && continue
  IFS=':' read -ra parts <<< "$module"
  full=""
  parent=""
  for i in "${!parts[@]}"; do
    part="${parts[$i]}"
    if [ -z "$full" ]; then
      full="$part"
    else
      full="$full/$part"
    fi
    exists_node["$full"]=1
    append_child "$parent" "$full"
    parent="$full"
  done
done
unset IFS
print_node_children() {
  parent="$1"
  prefix="$2"
  list="${children[$parent]:-}"
  if [ -z "$list" ]; then
    return
  fi
  IFS=$'\n' read -rd '' -a arr <<<"$list" || true
  count=${#arr[@]}
  for idx in "${!arr[@]}"; do
    child_full="${arr[$idx]}"
    label="${child_full##*/}"
    if [ "$idx" -eq $((count-1)) ]; then
      branch="└─ "
      next_prefix="${prefix}   "
    else
      branch="├─ "
      next_prefix="${prefix}│  "
    fi
    printf "%s%s[%s](./%s)\n" "$prefix" "$branch" "$label" "$child_full" >> "$tmpfile"
    print_node_children "$child_full" "$next_prefix"
  done
  unset IFS
}
{
  echo '```text'
  echo "$root_name"
} > "$tmpfile"
print_node_children "" ""
echo '```' >> "$tmpfile"
start="<!-- START_STRUCTURE -->"
end="<!-- END_STRUCTURE -->"
content="$(cat "$tmpfile")"
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
rm -f "$tmpfile"
