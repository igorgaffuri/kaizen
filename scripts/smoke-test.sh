#!/usr/bin/env bash
# Kaizen skill smoke test
# Verifies structural integrity, cron payload consistency, and live-system sync.
# Exit 0 = all pass, 1 = at least one failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="${HOME}/.openclaw/workspace"
SQLITE="${HOME}/.openclaw/state/openclaw.sqlite"

PASS=0
FAIL=0
FAILS=()

if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
else
  GREEN=''; RED=''; CYAN=''; NC=''
fi

ok()   { PASS=$((PASS+1)); printf "  ${GREEN}[ok]${NC} %s\n" "$*"; }
fail() { FAIL=$((FAIL+1)); FAILS+=("$*"); printf "  ${RED}[FAIL]${NC} %s\n" "$*"; }
info() { printf "  ${CYAN}[info]${NC} %s\n" "$*"; }
hdr()  { printf "\n${CYAN}== %s ==${NC}\n" "$*"; }

# Read sqlite cell via temp python script (avoids quote-escaping issues in -c)
sqlite_get() {
  local sql="$1"
  local tmpf
  tmpf=$(mktemp /tmp/smoke-sql.XXXXXX.py)
  cat > "$tmpf" <<PYEOF
import sqlite3
db = sqlite3.connect("$SQLITE")
cur = db.cursor()
cur.execute("""$sql""")
row = cur.fetchone()
if row:
    print(row[0] if row[0] is not None else '')
PYEOF
  python3 "$tmpf" 2>/dev/null
  rm -f "$tmpf"
}

# -------------------- 1. STRUCTURAL --------------------
hdr "1. Structural"

for f in SKILL.md README.md LICENSE lib/pre-conclusion-gate.md lib/binary-assertions.md \
         lib/wal-protocol.md lib/heartbeat.md lib/learning-loop.md lib/reverse-prompting.md \
         lib/tool-migration.md lib/triggers.md lib/working-buffer.md lib/reflexion-loop.md \
         lib/self-correction-loop.md lib/progress-narration.md \
         docs/ARCHITECTURE.md docs/MIGRATION.md docs/SETUP.md \
         templates/session-state.md templates/working-buffer.md templates/reflexion-log.md \
         templates/recurring-patterns.md templates/outcome-journal.md \
         scripts/tools-migration-check.sh scripts/smoke-test.sh; do
  if [ -f "$ROOT/$f" ]; then ok "$f present"
  else fail "$f missing"
  fi
done

[ -x "$ROOT/scripts/tools-migration-check.sh" ] && ok "tools-migration-check.sh executable" \
  || fail "tools-migration-check.sh NOT executable"
[ -x "$SCRIPT_DIR/smoke-test.sh" ] && ok "smoke-test.sh self-executable" \
  || fail "smoke-test.sh NOT executable"

fm=$(head -10 "$ROOT/SKILL.md")
echo "$fm" | grep -q "^name: kaizen" && ok "SKILL.md has name=kaizen" || fail "SKILL.md missing name"
echo "$fm" | grep -q "^version: " && ok "SKILL.md has version" || fail "SKILL.md missing version"
echo "$fm" | grep -q "^description: " && ok "SKILL.md has description" || fail "SKILL.md missing description"

empty_md=$(find "$ROOT" -name "*.md" -size 0 2>/dev/null | wc -l)
[ "$empty_md" -eq 0 ] && ok "no empty .md files" || fail "$empty_md empty .md files"

# -------------------- 2. SETUP.md SYNC --------------------
hdr "2. SETUP.md cron examples"

cron_examples=$(grep -c "^## Cron " "$ROOT/docs/SETUP.md" 2>/dev/null || echo 0)
[ "$cron_examples" -ge 5 ] && ok "SETUP.md has $cron_examples cron examples (>=5)" \
  || fail "SETUP.md has $cron_examples cron examples (expected >=5)"

# REGRA DE BUSCA: count occurrences in message fields (not just header lines)
sections=$(grep -o "REGRA DE BUSCA" "$ROOT/docs/SETUP.md" | wc -l)
[ "$sections" -ge 5 ] && ok "REGRA DE BUSCA appears $sections times in SETUP.md (>=5)" \
  || fail "REGRA DE BUSCA appears $sections times (expected >=5)"

gates=$(grep -o "PRE-CONCLUSION VERIFICATION GATE" "$ROOT/docs/SETUP.md" | wc -l)
[ "$gates" -ge 5 ] && ok "PRE-CONCLUSION GATE appears $gates times in SETUP.md (>=5)" \
  || fail "PRE-CONCLUSION GATE appears $gates times (expected >=5)"

# -------------------- 3. WORKSPACE --------------------
hdr "3. Workspace integration"

[ -d "$WORKSPACE/skills/kaizen" ] && ok "kaizen skill present in workspace" \
  || fail "kaizen skill NOT in $WORKSPACE/skills/"

for f in MEMORY.md TOOLS.md USER.md IDENTITY.md SOUL.md AGENTS.md HEARTBEAT.md SESSION-STATE.md; do
  [ -f "$WORKSPACE/$f" ] && ok "$WORKSPACE/$f present" || fail "$WORKSPACE/$f missing"
done

for s in "Proactive Behaviors" "Security" "Self-Healing" "Memory" "Proactive Surprise"; do
  grep -q "$s" "$WORKSPACE/HEARTBEAT.md" && ok "HEARTBEAT.md has section: $s" \
    || fail "HEARTBEAT.md missing section: $s"
done

if [ -s "$WORKSPACE/MEMORY.md" ] && ! grep -q "^_(no content yet)_\|placeholder" "$WORKSPACE/MEMORY.md"; then
  ok "MEMORY.md has real content"
else
  fail "MEMORY.md empty or template"
fi

# -------------------- 4. CRONS (LIVE) --------------------
hdr "4. Crons (live)"

if [ ! -f "$SQLITE" ]; then
  fail "SQLite not found at $SQLITE"
else
  ok "SQLite present"

  # Look up jobs by name (stable across reinstalls), not by hardcoded UUID.
  # UUIDs drift when crons are recreated via `openclaw cron action=add`; names don't.
  KAIZEN_JOB_NAMES=(
    "kaizen-daily-digest"
    "kaizen-learning-review-weekly"
    "kaizen-docs-curator-weekly"
    "kaizen-reverse-prompting-weekly"
    "kaizen-pattern-automation-monthly"
    "kaizen-health-daily"
  )

  declare -A JOB_IDS
  for name in "${KAIZEN_JOB_NAMES[@]}"; do
    job_id=$(sqlite_get "SELECT job_id FROM cron_jobs WHERE name = '$name'")
    if [ -n "$job_id" ]; then
      JOB_IDS["$name"]="$job_id"
      ok "cron present: $name"
    else
      fail "cron missing: $name"
    fi
  done

  for name in "${KAIZEN_JOB_NAMES[@]}"; do
    job_id="${JOB_IDS[$name]:-}"
    [ -z "$job_id" ] && continue
    has_gate=$(sqlite_get "SELECT CASE WHEN job_json LIKE '%PRE-CONCLUSION%' THEN 1 ELSE 0 END FROM cron_jobs WHERE job_id = '$job_id'")
    if [ "$has_gate" = "1" ]; then ok "GATE present in: $name"
    else fail "GATE MISSING in: $name"; fi
  done

  for name in "${KAIZEN_JOB_NAMES[@]}"; do
    job_id="${JOB_IDS[$name]:-}"
    [ -z "$job_id" ] && continue
    enabled=$(sqlite_get "SELECT enabled FROM cron_jobs WHERE job_id = '$job_id'")
    tz=$(sqlite_get "SELECT schedule_tz FROM cron_jobs WHERE job_id = '$job_id'")
    expr=$(sqlite_get "SELECT schedule_expr FROM cron_jobs WHERE job_id = '$job_id'")
    if [ "$enabled" = "1" ] && [ "$tz" = "America/Sao_Paulo" ] && [ -n "$expr" ]; then
      ok "$name: enabled=$enabled tz=$tz expr='$expr'"
    else
      fail "$name: enabled=$enabled tz=$tz expr='$expr'"
    fi
  done

  for name in "${KAIZEN_JOB_NAMES[@]}"; do
    job_id="${JOB_IDS[$name]:-}"
    [ -z "$job_id" ] && continue
    target=$(sqlite_get "SELECT delivery_to FROM cron_jobs WHERE job_id = '$job_id'")
    if [ "$target" = "telegram:8157279145" ]; then ok "$name: delivery=$target"
    else fail "$name: delivery=$target"; fi
  done
fi

# -------------------- 5. GIT --------------------
hdr "5. Git state"

cd "$ROOT" || exit 1

branch=$(git branch --show-current 2>/dev/null)
[ "$branch" = "main" ] && ok "on main branch" || fail "on branch: $branch (expected main)"

if [ -z "$(git status --porcelain)" ]; then ok "working tree clean"
else fail "working tree dirty:"; git status --short | sed 's/^/    /'; fi

last_commit=$(git log --oneline -1 2>/dev/null)
[ -n "$last_commit" ] && ok "last commit: $last_commit" || fail "no commits"

remote=$(git remote get-url origin 2>/dev/null)
[ -n "$remote" ] && ok "origin: $remote" || fail "no origin remote"

unpushed=$(git log --oneline "origin/${branch}..${branch}" 2>/dev/null | wc -l)
if [ "$unpushed" -eq 0 ]; then
  ok "no unpushed commits"
elif [ "$remote" = "https://github.com/igorgaffuri/kaizen.git" ]; then
  # Upstream-only clone (not fork): push denied with 403. Not the user's fault.
  info "$unpushed unpushed commits (upstream-only clone, push blocked — expected)"
else
  fail "$unpushed unpushed commits"
fi

# -------------------- SUMMARY --------------------
echo ""
printf "${CYAN}==================== SUMMARY ====================${NC}\n"
printf "  ${GREEN}PASS: %d${NC}  ${RED}FAIL: %d${NC}\n" "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  for f in "${FAILS[@]}"; do
    printf "  ${RED}-${NC} %s\n" "$f"
  done
  exit 1
fi
echo ""
echo "All checks passed."
exit 0
