#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "error: prune.sh does not accept arguments" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/../../.agent-memory" ]; then
  ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
  ROOT_DIR="${PWD}"
fi
MEMORY_DIR="$ROOT_DIR/.agent-memory"
TASKS_PATH="$MEMORY_DIR/tasks.json"
ARTIFACTS_DIR="$MEMORY_DIR/artifacts"
AGENT_PROTOCOL_PATH="$MEMORY_DIR/agent-protocol.md"

mkdir -p "$ARTIFACTS_DIR/review" "$ARTIFACTS_DIR/plan" "$ARTIFACTS_DIR/prompt" "$ARTIFACTS_DIR/done"

if [ ! -f "$TASKS_PATH" ]; then
  printf '{"tasks": []}\n' > "$TASKS_PATH"
  echo "  - .agent-memory/tasks.json missing, created empty task index"
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required but not installed" >&2
  exit 1
fi

python3 - "$MEMORY_DIR" "$TASKS_PATH" "$AGENT_PROTOCOL_PATH" <<'PY'
import json
import os
import sys
from pathlib import Path

memory_dir = Path(sys.argv[1])
tasks_path = Path(sys.argv[2])
agent_protocol_path = Path(sys.argv[3])
artifacts_dir = memory_dir / "artifacts"

try:
    data = json.loads(tasks_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    print(f"error: invalid tasks.json at {tasks_path}: {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(data, dict) or not isinstance(data.get("tasks"), list):
    print(f"error: invalid tasks.json structure at {tasks_path}: expected {{\"tasks\": []}}", file=sys.stderr)
    sys.exit(1)

tasks = data["tasks"]
active_statuses = {"pending", "in_progress", "blocked"}
terminal_statuses = {"done", "cancelled"}

active_tasks = []
removed_tasks = []
unknown_status_tasks = []

for task in tasks:
    status = task.get("status")
    if status in active_statuses:
        active_tasks.append(task)
    elif status in terminal_statuses:
        removed_tasks.append(task)
    else:
        unknown_status_tasks.append(task.get("id", "<unknown>"))

if unknown_status_tasks:
    ids = ", ".join(unknown_status_tasks)
    print(f"error: unsupported task status found in tasks.json: {ids}", file=sys.stderr)
    sys.exit(1)

def collect_refs(task):
    refs = set()
    for key in ("origin_artifact_id", "prompt_artifact_id"):
        value = task.get(key)
        if isinstance(value, str) and value:
            refs.add(value)
    artifact_refs = task.get("artifact_refs")
    if isinstance(artifact_refs, list):
        for value in artifact_refs:
            if isinstance(value, str) and value:
                refs.add(value)
    return refs

active_refs = set()
for task in active_tasks:
    active_refs.update(collect_refs(task))

removed_refs = set()
for task in removed_tasks:
    removed_refs.update(collect_refs(task))

prunable_refs = removed_refs - active_refs

artifact_id_to_paths = {}
for subdir in ("review", "plan", "prompt", "done"):
    base = artifacts_dir / subdir
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if not path.is_file():
            continue
        artifact_id = None
        try:
            with path.open("r", encoding="utf-8") as handle:
                for _ in range(30):
                    line = handle.readline()
                    if not line:
                        break
                    if line.startswith("artifact_id:"):
                        artifact_id = line.split(":", 1)[1].strip()
                        break
        except UnicodeDecodeError:
            artifact_id = None
        if artifact_id:
            artifact_id_to_paths.setdefault(artifact_id, []).append(path)

deleted_done_files = []
done_dir = artifacts_dir / "done"
if done_dir.exists():
    for path in sorted(done_dir.rglob("*"), reverse=True):
        if path.is_file():
            path.unlink()
            deleted_done_files.append(path.relative_to(memory_dir).as_posix())
    for path in sorted(done_dir.rglob("*"), reverse=True):
        if path.is_dir():
            try:
                path.rmdir()
            except OSError:
                pass

deleted_ref_files = []
missing_ref_ids = []
for artifact_id in sorted(prunable_refs):
    all_matched_paths = artifact_id_to_paths.get(artifact_id, [])
    matched_paths = [
        path for path in all_matched_paths
        if any(part in {"review", "plan", "prompt"} for part in path.relative_to(artifacts_dir).parts[:1])
    ]
    if not matched_paths:
        if not all_matched_paths:
            missing_ref_ids.append(artifact_id)
        continue
    for path in matched_paths:
        if path.exists():
            path.unlink()
            deleted_ref_files.append(path.relative_to(memory_dir).as_posix())

for subdir in ("review", "plan", "prompt"):
    base = artifacts_dir / subdir
    if base.exists():
        for path in sorted(base.rglob("*"), reverse=True):
            if path.is_dir():
                try:
                    path.rmdir()
                except OSError:
                    pass

data["tasks"] = active_tasks
tasks_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print("✓ agent-protocol history pruned")
print(f"  - preserved tasks: {len(active_tasks)}")
print(f"  - removed terminal tasks: {len(removed_tasks)}")
print(f"  - deleted done artifacts: {len(deleted_done_files)}")
print(f"  - deleted review/plan/prompt artifacts: {len(deleted_ref_files)}")
if missing_ref_ids:
    print(f"  - referenced artifact ids not found on disk: {', '.join(sorted(missing_ref_ids))}")
if agent_protocol_path.exists():
    print("  - preserved .agent-memory/agent-protocol.md")
else:
    print("  - .agent-memory/agent-protocol.md not present")
PY
