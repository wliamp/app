#!/usr/bin/env bash
set -euo pipefail

echo "🏗️ Generating full repository overview..."

# ---------- Ensure running from repo root ----------
cd "$(git rev-parse --show-toplevel)"

# ---------- 1️⃣ Generate Mermaid folder/file structure ----------
generate_structure() {
    echo "```mermaid"
    echo "graph TD"
    echo "    A[📁 root]"
    id_counter=0

    traverse() {
        local path=$1
        local parent_id=$2
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

# ---------- 2️⃣ Generate Ruleset from GitHub branch protection ----------
generate_ruleset() {
    echo "### 🛡 Branch Protection Rules (from GitHub API)"
    echo ""

    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        echo "- ⚠️ GITHUB_TOKEN not set, cannot fetch branch protection rules."
        return
    fi

    python3 - <<'EOF'
import os, requests

repo_full = os.environ['GITHUB_REPOSITORY']
token = os.environ['GITHUB_TOKEN']
headers = {"Authorization": f"token {token}"}

branches_url = f"https://api.github.com/repos/{repo_full}/branches"
resp = requests.get(branches_url, headers=headers)
if resp.status_code != 200:
    print(f"- ⚠️ Failed to fetch branches: {resp.status_code}")
    exit(1)
branches = [b['name'] for b in resp.json()]

for branch in branches:
    url = f"https://api.github.com/repos/{repo_full}/branches/{branch}/protection"
    r = requests.get(url, headers=headers)
    if r.status_code != 200:
        print(f"#### 🔒 Branch `{branch}`")
        print("- No protection rules set")
        continue
    data = r.json()
    print(f"#### 🔒 Branch `{branch}`")
    admins = data.get("enforce_admins", {}).get("enabled", False)
    print(f"- Enforce admins: {admins}")

    restrictions = data.get("restrictions", None)
    if restrictions:
        users = [u["login"] for u in restrictions.get("users", [])]
        teams = [t["name"] for t in restrictions.get("teams", [])]
        print(f"- Restrictions: users={users}, teams={teams}")
    else:
        print("- Restrictions: None")

    rsc = data.get("required_status_checks", {})
    if rsc:
        contexts = rsc.get("contexts", [])
        strict = rsc.get("strict", False)
        print(f"- Status checks required: {contexts}, strict={strict}")
    else:
        print("- Status checks required: None")

    pr = data.get("required_pull_request_reviews", {})
    if pr:
        print("- Pull request reviews:")
        print(f"    - dismiss stale reviews: {pr.get('dismiss_stale_reviews', False)}")
        print(f"    - require code owner reviews: {pr.get('require_code_owner_reviews', False)}")
    else:
        print("- Pull request reviews: None")
EOF

    echo ""
}

# ---------- 3️⃣ Generate Text-Based Explanation for all .yml in .github/ ----------
generate_all_yml() {
    echo "### 📄 All GitHub YAML Configs (.github/)"
    echo ""

    for yml in $(find .github -type f -name "*.yml"); do
        [[ -f "$yml" ]] || continue
        python3 - <<EOF
import yaml
yml_file = "$yml"
try:
    with open(yml_file) as f:
        data = yaml.safe_load(f) or {}
except Exception as e:
    print(f"- {yml_file}: could not parse YAML ({e})")
    exit(0)

name = data.get("name", yml_file)
print(f"- **File:** {yml_file} / **Name:** {name}")

triggers = data.get("on", None)
print(f"  - Triggered on: {triggers}")

jobs = data.get("jobs", {})
for jname, job in jobs.items():
    runs_on = job.get("runs-on","unknown")
    print(f"  - Job: {jname} (runs on {runs_on})")
    for step in job.get("steps", []):
        if "run" in step:
            cmd = step["run"].replace('\n','; ')
            print(f"      * Step: run → {cmd}")
        elif "uses" in step:
            print(f"      * Step: uses → {step['uses']}")
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

# ---------- Generate temporary content ----------
generate_structure > structure.tmp
generate_ruleset > ruleset.tmp
generate_all_yml > workflows.tmp

# ---------- Update README ----------
update_section STRUCTURE_START STRUCTURE_END structure.tmp
update_section RULESET_START RULESET_END ruleset.tmp
update_section WORKFLOWS_START WORKFLOWS_END workflows.tmp

rm -f structure.tmp ruleset.tmp workflows.tmp
echo "✅ README.md fully updated."
