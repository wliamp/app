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
echo '```text' > "$tmpfile"
echo "$root_name" >> "$tmpfile"
grep -E "include" "$settings_file" \
  | sed "s/include//" \
  | tr -d "'" \
  | tr ',' '\n' \
  | sed '/^\s*$/d' \
  | while read -r module; do
      module=$(echo "$module" | xargs)
      IFS=':' read -ra parts <<< "$module"
      path_acc=""
      for ((i=0; i<${#parts[@]}; i++)); do
          part="${parts[$i]}"
          if [ -z "$path_acc" ]; then
              path_acc="$part"
          else
              path_acc="$path_acc/$part"
          fi
          indent=$(printf "%${i}s" "")
          indent="${indent// /│  }"
          branch="├─"
          echo "$indent$branch [${part}](./${path_acc})" >> "$tmpfile"
      done
  done
echo '```' >> "$tmpfile"
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
