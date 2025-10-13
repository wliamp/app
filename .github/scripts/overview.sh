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
echo "$includes" | tr ' ' '\n' | while read -r module; do
  [[ -z "$module" ]] && continue
  IFS=':' read -ra parts <<< "$module"
  depth=${#parts[@]}
  indent=""
  for ((i=1; i<depth; i++)); do
    indent="${indent}&nbsp;&nbsp;&nbsp;&nbsp;"
  done
  if (( depth == 1 )); then
    echo "├─ [${parts[-1]}](./${parts[0]})<br>" >> "$tmpfile"
  else
    parent_path=$(IFS='/'; echo "${parts[*]:0:$((depth-1))}")
    child="${parts[-1]}"
    echo "${indent}└─ [${child}](./${parent_path}/${child})<br>" >> "$tmpfile"
  fi
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
