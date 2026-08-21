#!/usr/bin/env bash
# Validate skill folders: well-formedness, and that nothing names a specific agent.
#
# A malformed skill does not raise an error at runtime — it silently stops triggering,
# which is why these checks exist at all. Every failure prints the offending path.
#
# Usage: scripts/validate.sh [SKILLS_DIR]     (default: skills)
#
# Targets bash 3.2 so it runs on stock macOS: no associative arrays, no mapfile.

set -euo pipefail

SKILLS_DIR="${1:-skills}"

# One reader for frontmatter, shared with install.sh so the two can never disagree
# about what a skill's description says.
# shellcheck source=scripts/frontmatter.sh
. "$(dirname "$0")/frontmatter.sh"

# Backticked identifiers that are not skills in this repo and must not be reported as
# dangling references. Three groups, one per line: SKILL.md frontmatter field names; tools
# or plugins that live outside this repo; and subcommands of those tools, which read as
# bare words once backticked (`gh stack link` is written as \`link\` in prose).
ALLOWED_IDENTS="
allowed-tools argument-hint disable-model-invocation skill-name paths metadata
code-review general-purpose migration-safety skill-creator update-config
gh git jq bats stow make sed awk grep find rg go uv npm pnpm cargo shellcheck
gh-stack link submit
"

# Skills that exist in the author's wider setup but are deliberately not published here.
# The generic reference checks below cannot catch these on their own: `remember` is a plain
# English word, so a bare-word search would fire on trigger phrases like "what should you
# remember from this". Listing them lets the check demand a reference-shaped mention instead.
# Add a name here whenever a skill is dropped from this repo.
ABSENT_SKILLS="remember work-log"

# Verbs that turn a bare word into a skill reference.
REF_VERBS="use|via|invoke|hand off to|handed off to|offer"

# House limits from the write-skill conventions. Both are silent failures when broken: an
# over-long description is truncated, and the tail is the NOT-for boundary that keeps two
# skills from fighting over the same request. Overflow belongs in a bundled file.
MAX_DESC=1024
MAX_LINES=150

# Paths that name one agent. A skill must not contain these; see CLAUDE.md.
# The tilde is bracketed so it reads as a regex literal, not a home-directory expansion.
HOST_PATH_RE='[~]/\.claude/|[~]/\.cursor/|\.claude/scratch/|\.cursor/'

# The one file allowed to name agents, because listing per-agent locations is its job.
HOST_PATH_EXEMPT="self-improve/AGENT-STRATEGIES.md"

fail=0
err() {
	printf 'FAIL  %s\n' "$*" >&2
	fail=1
}

if [ ! -d "$SKILLS_DIR" ]; then
	printf 'error: no such directory: %s\n' "$SKILLS_DIR" >&2
	exit 2
fi

# Skill names are the directory names. Wrapped in spaces so `case` can test membership
# without an associative array.
known_skills=" "
for dir in "$SKILLS_DIR"/*/; do
	[ -d "$dir" ] || continue
	known_skills="$known_skills$(basename "$dir") "
done

allowed_idents=" $(echo "$ALLOWED_IDENTS" | tr '\n' ' ' | tr -s ' ') "

is_known() { case "$known_skills" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
is_allowed() { case "$allowed_idents" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# --- per-skill checks -------------------------------------------------------

for dir in "$SKILLS_DIR"/*/; do
	[ -d "$dir" ] || continue
	skill=$(basename "$dir")
	md="${dir%/}/SKILL.md"

	if [ ! -f "$md" ]; then
		err "$dir — no SKILL.md"
		continue
	fi

	# Frontmatter is the block between the first two `---` lines.
	if [ "$(head -n 1 "$md")" != "---" ]; then
		err "$md — does not start with a --- frontmatter block"
		continue
	fi
	name=$(skill_field "$md" name)
	desc=$(skill_field "$md" description)

	# Cursor rejects a skill outright when `name` does not match its folder.
	if [ -z "$name" ]; then
		err "$md — frontmatter has no 'name'"
	elif [ "$name" != "$skill" ]; then
		err "$md — name '$name' does not match folder '$skill'"
	fi

	if [ -z "$desc" ]; then
		err "$md — frontmatter has no 'description'"
	elif [ "${#desc}" -gt "$MAX_DESC" ]; then
		err "$md — description is ${#desc} chars, over the $MAX_DESC limit"
	fi

	skill_lines=$(wc -l <"$md" | tr -d ' ')
	if [ "$skill_lines" -ge "$MAX_LINES" ]; then
		err "$md — $skill_lines lines; move overflow to a bundled file (limit $MAX_LINES)"
	fi

	# Every skill declares its tools, so a missing one is caught here rather than as a
	# refused tool call halfway through a run.
	tools=$(skill_field "$md" allowed-tools)
	if [ -z "$tools" ]; then
		err "$md — frontmatter has no 'allowed-tools'"
	elif [ -n "$(find "${dir%/}" -name '*.md' ! -name 'SKILL.md' -print -quit)" ]; then
		# A skill pointed at its own bundled file needs Read, or it fails at the worst moment.
		case " $tools " in
		*" Read "*) ;;
		*) err "$md — bundles files but 'allowed-tools' has no Read" ;;
		esac
	fi
done

# --- repo-wide checks over every markdown file ------------------------------

while IFS= read -r file; do
	rel="${file#"$SKILLS_DIR"/}"
	dirname_of=$(dirname "$file")

	# Relative links must resolve, or a skill points at a file nobody can open.
	# Links inside fenced blocks or inline code spans are sample text in a template,
	# not links — a skill's own examples routinely name files that do not exist here.
	while IFS= read -r target; do
		[ -n "$target" ] || continue
		case "$target" in
		http://* | https://* | mailto:* | '#'*) continue ;;
		esac
		target="${target%%#*}"
		[ -n "$target" ] || continue
		case "$target" in
		/*) probe="$target" ;;
		*) probe="$dirname_of/$target" ;;
		esac
		[ -e "$probe" ] || err "$file — broken link: $target"
	done <<-EOF
		$(awk '
			/^[[:space:]]*```/ { infence = !infence; next }
			infence { next }
			{ line = $0; gsub(/`[^`]*`/, "", line); print line }
		' "$file" | grep -oE '\]\([^)]+\)' | sed 's/^](//; s/)$//' || true)
	EOF

	# No skill may name a specific agent's directories.
	if [ "$rel" != "$HOST_PATH_EXEMPT" ]; then
		while IFS= read -r hit; do
			[ -n "$hit" ] || continue
			err "$file — host-specific path: $hit"
		done <<-EOF
			$(grep -noE "$HOST_PATH_RE" "$file" | sort -u -t: -k2 | head -n 5)
		EOF
	fi

	# A pointer to a skill that is not in this repo is a dead end for the reader.
	# Pass A: hyphenated identifiers, which are shaped like skill names.
	# Pass B: any identifier used in a skill-reference phrase, which catches
	# single-word names such as `remember` that pass A cannot distinguish from prose.
	# The backticks below are literal regex characters, not command substitution.
	# shellcheck disable=SC2016
	refs=$(
		{
			grep -oE '`[a-z][a-z0-9]*(-[a-z0-9]+)+`' "$file" || true
			grep -oiE '(use|via|invoke|hand off to|handed off to|offer)[[:space:]]+`[a-z][a-z0-9-]*`' "$file" || true
			grep -oE '`[a-z][a-z0-9-]*`[[:space:]]+skill' "$file" || true
		} | grep -oE '`[a-z][a-z0-9-]*`' | tr -d '`' | sort -u
	) || true
	while IFS= read -r ref; do
		[ -n "$ref" ] || continue
		is_known "$ref" && continue
		is_allowed "$ref" && continue
		# Pass C reports these with a clearer message; don't say it twice.
		case " $ABSENT_SKILLS " in *" $ref "*) continue ;; esac
		err "$file — references '$ref', which is not a skill in $SKILLS_DIR/"
	done <<-EOF
		$refs
	EOF

	# Pass C: a dropped skill named in reference shape — backticked anywhere, or bare
	# after a reference verb. Both forms point the reader at something they cannot install.
	for absent in $ABSENT_SKILLS; do
		is_known "$absent" && continue
		# shellcheck disable=SC2016
		if grep -qE "\`$absent\`|($REF_VERBS)[[:space:]]+$absent\b" "$file"; then
			err "$file — references dropped skill '$absent'"
		fi
	done
done <<-EOF
	$(find "$SKILLS_DIR" -type f -name '*.md' | sort)
EOF

if [ "$fail" -ne 0 ]; then
	printf '\nvalidate: FAILED\n' >&2
	exit 1
fi

printf 'validate: ok (%s skills)\n' "$(echo "$known_skills" | wc -w | tr -d ' ')"
