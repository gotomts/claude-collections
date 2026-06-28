#!/usr/bin/env bash
# PreToolUse hook: lift the user-scope `Bash(git push:*)` deny only when the
# push is (a) not a force variant and (b) not targeting main/master.
# Anything riskier is left to fall through to the existing deny rules so the
# usual prompt / block fires.
set -u

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# 1. Force-push variants — never auto-allow.
if printf '%s' "$cmd" | grep -qE -- '(--force([= ]|$)|--force-with-lease|(^|[[:space:]])-f([[:space:]]|$))'; then
  exit 0
fi

# 2. Tokenize args after `git push`, dropping option flags and surrounding
#    quotes so things like `git push -u origin "main"` resolve correctly.
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

# 3. Refspec starting with `+` is force-push shorthand — never auto-allow,
#    even when the destination would otherwise be a non-main branch.
if [ "${#positional[@]}" -ge 2 ]; then
  for ref in "${positional[@]:1}"; do
    case "$ref" in
      +*) exit 0 ;;
    esac
  done
fi

# 4. Defer if any push target resolves to main/master.
#    Normalize: drop refspec sigil, take part after last `:`, strip refs/heads/.
#    positional = [remote, refspec1, refspec2, ...]; no refspec → current branch.
normalize_dst() {
  local d="${1#+}"
  d="${d##*:}"
  d="${d#refs/heads/}"
  printf '%s' "$d"
}
check_dst() {
  case "$1" in
    main|master|*/main|*/master) exit 0 ;;
  esac
}
if [ "${#positional[@]}" -ge 2 ]; then
  for ref in "${positional[@]:1}"; do
    dst=$(normalize_dst "$ref")
    check_dst "$dst"
  done
else
  dst=$(git symbolic-ref --short HEAD 2>/dev/null || true)
  check_dst "$dst"
fi

# 4. Otherwise: explicit allow.
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"claude-collections: non-main / non-force push auto-allowed"}}'
