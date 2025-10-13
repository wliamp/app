#!/usr/bin/env bash
set -euo pipefail

echo "🏗️ Generating full repository overview..."

# ---------- 1️⃣ Mermaid folder/file structure ----------
generate_structure() {
  echo "```mermaid"
  echo "graph TD"
  echo "    A[📁 root]"
  id_counter=0

  traverse() {
    local path=$1
    local parent_id=$2
    [[ -d "$path" ]] || return
    for item in "$path"/*; do
      [[ -e "$item" ]] || continue
      id_counter=$((id_counter+1))
      local node_id="N$id_counter"
      local name=$(basename "$item")
      if [[ -d "$item" ]]; then
        echo "    $parent_id --> $node_id[📁 $name]"
        traverse "$item" "$node_id"
      else
        echo "    $parent_id --> $node_id[📄 $name]"
      fi
    done
  }

  traverse "." "A"
  echo "```"
}

# ---------- 2️⃣ GitHub branch protection rules ----------
generate_ruleset() {
  echo "### 🛡 Branch Protection Rules (from GitHub API)"
  echo ""

  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "⚠️ GITHUB_TOKEN is not set. Cannot fetch branch protection rules."
    return
  fi

  python3 - <<'EOF'
import os, requests

repo = os.environ['GITHUB_REPOSITORY']
token = os.environ['GITHUB_TOKEN']
headers = {"Authorization": f"token {token}"}

branches = requests.get(f"https://api.github.com/repos/{repo}/branches", headers=headers).json()
for b in branches:
    branch = b["name"]
    url = f"https://api.github.com/repos/{repo}/branches/{branch}/protection"
    r = requests.get(url, headers=headers)
    print(f"#### 🔒 Branch `{branch}`")
    if r.status_code != 200:
        print("- No protection rules set\n")
        continue
    data = r.json()
    admins = data.get("enforce_admins", {}).get("enabled", False)
    print(f"- Enforce admins: {admins}")
    restrictions = data.get("restrictions", None)
    if restrictions:
        users = [u["login"] for u in restrictions.get("users",[])]
        teams = [t["name"] for t in restrictions.get("teams",[])]
        print(f"- Restrictions: users={users}, teams={teams}")
    pr_reviews = data.get("required_pull_request_reviews", {})
    if pr_reviews:
        print(f"- Pull request reviews:")
        print(f"    - dismiss stale reviews: {pr_reviews.get('dismiss_stale_reviews', False)}")
        print(f"    - require code owner reviews: {pr_reviews.get('require_code_owner_reviews', False)}")
    status_checks = data.get("required_status_checks", {})
    if status_checks:
        contexts = status_checks.get("contexts", [])
        strict = status_checks.get("strict", False)
        print(f"- Status checks: contexts={contexts}, strict={strict}")
    print()
EOF
}

# ---------- 3️⃣ Text-based explanation for all .yml in .github ----------
generate_yml_docs() {
  echo "### 📄 GitHub YAML configs (.github/)"
  echo ""

  for yml in $(find .github -type f -name "*.yml"); do
    [[ -f "$yml" ]] || continue
    python3 - <<EOF
import yaml
yml_file = "$yml"
try:
    with open(yml_file) as f:
        data = yaml.safe_load(f)
except Exception as e:
    print(f"- {yml_file}: could not parse YAML ({e})\n")
    exit(0)

name = data.get("name", yml_file)
print(f"- **File:** {yml_file} / **Name:** {name}")

triggers = data.get("on", {})
print(f"  - Triggered on: {triggers}")

jobs = data.get("jobs", {})
for jname, job in jobs.items():
    runs_on = job.get("runs-on","unknown")
    if isinstance(runs_on, list):
        runs_on = ", ".join(runs_on)
    print(f"  - Job: {jname} (runs on {runs_on})")
    if "if" in job:
        print(f"      * Condition: {job['if']}")
    if "strategy" in job:
        print(f"      * Strategy: {job['strategy']}")
    for step in job.get("steps", []):
        if "run" in step:
            cmd = step["run"].replace('\n','; ')
            print(f"      * Step: run → {cmd}")
        elif "uses" in step:
            print(f"      * Step: uses → {step['uses']}")
        if "with" in step:
            print(f"        inputs: {step['with']}")
print()
EOF
  done
}

# ---------- 4️⃣ Update README ----------
update_section() {
  local start_tag=$1
  local end_tag=$2
  local content_file=$3
  awk -v start="<!--${start_tag}-->" -v end="<!--${end_tag}-->" '
    BEGIN {inside=0}
    $0 ~ start {print; system("cat '"$content_file"'"); inside=1; next}
    $0 ~ end {inside=0; print; next}
    {if(!inside) print}
  ' README.md > tmp && mv tmp README.md
}

# ---------- Generate content ----------
generate_structure > structure.tmp
generate_ruleset > ruleset.tmp
generate_yml_docs > workflows.tmp

# ---------- Update README ----------
update_section STRUCTURE_START STRUCTURE_END structure.tmp
update_section RULESET_START RULESET_END ruleset.tmp
update_section WORKFLOWS_START WORKFLOWS_END workflows.tmp

rm -f structure.tmp ruleset.tmp workflows.tmp
echo "✅ README.md fully updated."
