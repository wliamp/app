#!/usr/bin/env bash
set -euo pipefail
echo "🏗️ Generating full repository overview..."

generate_structure() {
  echo "```mermaid"
  echo "graph TD"
  echo "    A[📁 root]"
  for scope in $(find . -mindepth 1 -maxdepth 1 -type d ! -path './.*' | sort); do
    scope_name=$(basename "$scope")
    sid="S_${scope_name//[-]/_}"
    echo "    A --> $sid[📁 $scope_name]"
    for module in $(find "$scope" -mindepth 1 -maxdepth 1 -type d ! -path '*/.*' | sort); do
      module_name=$(basename "$module")
      mid="M_${scope_name//[-]/_}_${module_name//[-]/_}"
      echo "    $sid --> $mid[📦 $module_name]"
      echo "    click $mid \"$scope_name/$module_name\" \"🔗 open\""
    done
    echo "    click $sid \"$scope_name\" \"🔗 open\""
  done
  echo "```"
}

generate_ruleset() {
  echo "### ⚙️ Detected Rules and Configurations"
  echo ""
  [[ -f ".editorconfig" ]] && echo "- 🧩 **EditorConfig** detected"
  [[ -f ".ruleset.yml" ]] && echo "- 🛡️ **Code Ruleset** configured in \`.ruleset.yml\`"
  [[ -f "build.gradle" ]] && echo "- 🧱 **Gradle project root**"
  [[ -d ".github/actions" ]] && echo "- 🔧 **Custom GitHub Actions** found in \`.github/actions\`"
  [[ -f "settings.gradle" ]] && echo "- ⚙️ **Multi-module Gradle project** setup"
  echo ""
}

generate_workflows() {
  echo "### 🚀 CI/CD Workflows"
  for wf in .github/workflows/*.yml; do
    [[ -f "$wf" ]] || continue
    name=$(grep -m1 '^name:' "$wf" | cut -d':' -f2- | xargs)
    triggers=$(grep -E '^(on:|  push:|  pull_request:|  workflow_dispatch:|  schedule:)' "$wf" | sed 's/^/    /')
    echo "- **$name**"
    echo "  \`\`\`yaml"
    echo "$triggers"
    echo "  \`\`\`"
  done
}

update_section() {
  local start_tag=$1
  local end_tag=$2
  local content_file=$3
  awk -v start="<!--${start_tag}-->" -v end="<!--${end_tag}-->" -v file="$content_file" '
  $0 ~ start {print; system("cat " file); next}
  $0 ~ end {found=1}
  {print}
  ' README.md > tmp && mv tmp README.md
}

# Generate temporary content files
generate_structure > structure.tmp
generate_ruleset > ruleset.tmp
generate_workflows > workflows.tmp

# Update README sections
update_section STRUCTURE_START STRUCTURE_END structure.tmp
update_section RULESET_START RULESET_END ruleset.tmp
update_section WORKFLOWS_START WORKFLOWS_END workflows.tmp

rm -f structure.tmp ruleset.tmp workflows.tmp
echo "✅ README.md fully updated."
