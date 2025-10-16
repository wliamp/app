#!/bin/bash
set -euo pipefail
README="README.md"
TMPFILE="structure.tmp"
TMPDIR="tmp"
CHARTS_DIR="deploy/charts"
START="<!-- START_STRUCTURE -->"
END="<!-- END_STRUCTURE -->"
SETTINGS_FILE=$(ls | grep -E "settings.gradle(\.kts)?$" || true)
if [ -z "$SETTINGS_FILE" ]; then
  echo "❌ settings.gradle(.kts) NOT FOUND"
  exit 1
fi
ROOT_NAME=$(grep -E "^rootProject.name" "$SETTINGS_FILE" | sed "s/.*['\"]\\(.*\\)['\"].*/\\1/")
ROOT_NAME=${ROOT_NAME:-root}
echo "🗂️ ${ROOT_NAME}" > "$TMPFILE"
echo >> "$TMPFILE"
mkdir -p "$TMPDIR"
awk '
  /^[[:space:]]*include[[:space:]]*\(/ {
    match($0, /\(.*\)/)
    args = substr($0, RSTART+1, RLENGTH-2)
    gsub(/'\''|"/, "", args)
    gsub(/,/, " ", args)
    print args
  }
' "$SETTINGS_FILE" | tr '\n' ' ' > "$TMPDIR/modules_raw.txt"
if [ ! -s "$TMPDIR/modules_raw.txt" ]; then
  echo "⚠️ No modules found in $SETTINGS_FILE"
  exit 0
fi
read -r -a MODULES <<< "$(cat "$TMPDIR/modules_raw.txt")"
declare -A seen_top
top_levels=()
for m in "${MODULES[@]}"; do
  top="${m%%:*}"
  if [ -z "${seen_top[$top]:-}" ]; then
    seen_top[$top]=1
    top_levels+=("$top")
  fi
done
for top in "${top_levels[@]}"; do
  echo "├──── 📁 ${top} <a href=\"./${top}\">↗️</a>" >> "$TMPFILE"
  children=()
  for m in "${MODULES[@]}"; do
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
      echo "│     ${branch} 📄 ${child} <a href=\"./${fullpath}\">↗️</a>" >> "$TMPFILE"
    done
  fi
  echo "│" >> "$TMPFILE"
  echo >> "$TMPFILE"
done
CONTENT=$(cat "$TMPFILE")
if [ ! -f "$README" ]; then
  echo "# Project Overview" > "$README"
fi
if grep -q "$START" "$README" && grep -q "$END" "$README"; then
  awk -v s="$START" -v e="$END" -v r="$CONTENT" '
    $0~s {print; print r; skip=1; next}
    $0~e {skip=0}
    !skip
  ' "$README" > README.tmp && mv README.tmp "$README"
else
  echo -e "\n$START\n$CONTENT\n$END" >> "$README"
fi
echo "✅ README structure updated."
mkdir -p "$CHARTS_DIR"
echo "🧹 [cleanup] Checking for stale charts..."
find "$CHARTS_DIR" -mindepth 1 -type d -name "templates" -prune | while read -r chart_path; do
  rel_path="${chart_path#$CHARTS_DIR/}"
  rel_path="${rel_path%/templates}"
  module="${rel_path//\//:}"
  if [[ ! " ${MODULES[*]} " =~ " ${module} " ]]; then
    echo "   🗑️  Removing stale image chart: ${CHARTS_DIR}/${rel_path}"
    rm -rf "${CHARTS_DIR:?}/${rel_path}"
  fi
done
echo "🎯 [filter] Selecting only level-2 modules (for image charts)..."
LEVEL2_MODULES=()
for m in "${MODULES[@]}"; do
  colons=$(grep -o ":" <<< "$m" | wc -l || true)
  if [ "$colons" -eq 1 ]; then
    LEVEL2_MODULES+=("$m")
  fi
done
if [ "${#LEVEL2_MODULES[@]}" -eq 0 ]; then
  echo "⚠️  No level-2 modules found — skipping Helm image chart generation."
  exit 0
fi
echo "🚀 [generate] Creating Helm charts for ${#LEVEL2_MODULES[@]} image modules..."
for m in "${LEVEL2_MODULES[@]}"; do
  dirpath="${m//:/\/}"
  chart_dir="${CHARTS_DIR}/${dirpath}"
  image_path="${dirpath}"
  name="${m##*:}"
  mkdir -p "${chart_dir}/templates"
  echo "   📦 Generating chart for image '${image_path}' → ${chart_dir}"
  cat <<EOF > "${chart_dir}/Chart.yml"
apiVersion: v2
name: ${name}
description: Helm chart for Docker image '${image_path}'
type: application
version: 0.1.0
appVersion: "latest"
EOF
  cat <<EOF > "${chart_dir}/values.yml"
replicaCount: 1
image:
  repository: docker.io/\${{ vars.DOCKERHUB_REPO }}/${image_path}
  tag: "latest"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 8080
resources: {}
EOF
  cat <<EOF > "${chart_dir}/templates/deployment.yml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
EOF
  cat <<EOF > "${chart_dir}/templates/service.yml"
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ .Chart.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
EOF
  echo "   ✅ Chart ready for image '${image_path}'"
done
echo "🎉 All done! (README + Helm Charts updated)"
