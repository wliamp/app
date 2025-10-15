#!/bin/bash
set -e
settings_file=$(ls | grep -E "settings.gradle(\.kts)?$" || true)
if [ -z "$settings_file" ]; then
  echo "❌ settings.gradle(.kts) NOT FOUND"
  exit 1
fi
readme="README.md"
tmpfile="structure.tmp"
root_name=$(grep -E "^rootProject.name" "$settings_file" | sed "s/.*['\"]\\(.*\\)['\"].*/\\1/")
root_name=${root_name:-root}
echo "🗂️ ${root_name}" > "$tmpfile"
echo >> "$tmpfile"
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
read -r -a modules <<< "$includes"
declare -A seen_top
top_levels=()
for m in "${modules[@]}"; do
  top="${m%%:*}"
  if [ -z "${seen_top[$top]}" ]; then
    seen_top[$top]=1
    top_levels+=("$top")
  fi
done
for top in "${top_levels[@]}"; do
  echo "├──── 📁 ${top} <a href=\"./${top}\">↗️</a>" >> "$tmpfile"
  children=()
  for m in "${modules[@]}"; do
    if [[ "$m" == "$top"*:* ]]; then
      child="${m##*:}"
      children+=("$child|${m}")
    fi
  done
  count=${#children[@]}
  if (( count > 0 )); then
    for ((i=0; i<count; i++)); do
      pair="${children[$i]}"
      child="${pair%%|*}"
      fullpath="${pair#*|}"
      is_last=$(( i == count - 1 ))
      branch=$([ $is_last -eq 1 ] && echo "└────" || echo "├────")
      echo "│     ${branch} 📄 ${child} <a href=\"./${fullpath}\">↗️</a>" >> "$tmpfile"
    done
  fi
  echo "│" >> "$tmpfile"
  echo >> "$tmpfile"
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
