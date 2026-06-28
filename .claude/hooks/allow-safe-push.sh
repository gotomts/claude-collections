#!/usr/bin/env bash
# PreToolUse hook: authoritative decision for `git push`.
#   - non-force push to a non-protected branch → permissionDecision: allow
#   - force-push variants / protected branches (main, master, */main, */master)
#     → permissionDecision: ask  (user must confirm explicitly)
# Self-sufficient: does not rely on any user-scope deny rule firing.
set -u

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

emit() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  exit 0
}

# 1. Force-push flag variants — require explicit confirmation.
if printf '%s' "$cmd" | grep -qE -- '(--force([= ]|$)|--force-with-lease|(^|[[:space:]])-f([[:space:]]|$))'; then
  emit ask "force-push variant detected — manual confirmation required"
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

# 3. Refspec with leading `+` is force-push shorthand — require confirmation.
if [ "${#positional[@]}" -ge 2 ]; then
  for ref in "${positional[@]:1}"; do
    case "$ref" in
      +*) emit ask "force-push shorthand (+refspec) detected — manual confirmation required" ;;
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
        emit ask "push targets protected branch ($dst) — manual confirmation required"
        ;;
    esac
  done
else
  dst=$(git symbolic-ref --short HEAD 2>/dev/null || true)
  case "$dst" in
    main|master|*/main|*/master)
      emit ask "current branch is protected ($dst) — manual confirmation required"
      ;;
  esac
fi

# 5. Safe push — auto-allow.
emit allow "claude-collections: non-protected, non-force push auto-allowed"
