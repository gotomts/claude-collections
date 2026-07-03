#!/usr/bin/env bash
# PreToolUse hook: authoritative decision for `git push`.
#   - non-force push to a non-protected branch → permissionDecision: allow
#   - force-push variants / protected branches (main, master, */main, */master)
#     → permissionDecision: deny  (hard block — no prompt is shown so an
#                                  accidental click cannot bypass the guard).
#     To intentionally push these, edit this hook or push from outside Claude.
# Self-sufficient: does not rely on any user-scope deny rule firing.
set -u

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# 0. Early exit unless the command actually invokes `git push`.
#    Without this, downstream checks (`--force` regex, HEAD fallback) fire on
#    unrelated commands like `git worktree remove --force` or `git branch -D`
#    executed from main — both of which are legitimate cleanup operations.
if ! printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push([[:space:]]|$)'; then
  exit 0
fi

emit() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  exit 0
}

# 1. Force-push flag variants — hard block.
if printf '%s' "$cmd" | grep -qE -- '(--force([= ]|$)|--force-with-lease|(^|[[:space:]])-f([[:space:]]|$))'; then
  emit deny "force-push variant detected — blocked by claude-collections hook"
fi

# 2. Tokenize args after `git push`, dropping option flags and surrounding quotes.
args=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+push[[:space:]]*(.*)/\1/p')
positional=()
for tok in $args; do
  tok="${tok#\"}"; tok="${tok%\"}"
  tok="${tok#\'}"; tok="${tok%\'}"
  case "$tok" in
    -*) ;;  # drop option flags
    *)  positional+=("$tok") ;;
  esac
done

# 3. Refspec with leading `+` is force-push shorthand — hard block.
if [ "${#positional[@]}" -ge 2 ]; then
  for ref in "${positional[@]:1}"; do
    case "$ref" in
      +*) emit deny "force-push shorthand (+refspec) detected — blocked by claude-collections hook" ;;
    esac
  done
fi

# 4. Reject if any push target resolves to a protected branch.
normalize_dst() {
  local d="${1#+}"
  d="${d##*:}"
  d="${d#refs/heads/}"
  printf '%s' "$d"
}
if [ "${#positional[@]}" -ge 2 ]; then
  for ref in "${positional[@]:1}"; do
    dst=$(normalize_dst "$ref")
    case "$dst" in
      main|master|*/main|*/master)
        emit deny "push targets protected branch ($dst) — blocked by claude-collections hook"
        ;;
    esac
  done
else
  dst=$(git symbolic-ref --short HEAD 2>/dev/null || true)
  case "$dst" in
    main|master|*/main|*/master)
      emit deny "current branch is protected ($dst) — blocked by claude-collections hook"
      ;;
  esac
fi

# 5. Safe push — auto-allow.
emit allow "claude-collections: non-protected, non-force push auto-allowed"
