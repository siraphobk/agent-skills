#!/usr/bin/env bash
# Install this repo's skills into an agent's skills directory.
#
# Symlinks by default, so `git pull` in this clone is the update mechanism. Nothing is
# written until you name a target, and nothing is ever removed unless this script put it
# there — see "Ownership" below.
#
# Targets bash 3.2 so it runs on stock macOS: no associative arrays, no mapfile.

set -euo pipefail

# --- where we are ----------------------------------------------------------

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
SKILLS_DIR="$SELF_DIR/skills"
MARKER=".installed-from"

# shellcheck source=scripts/frontmatter.sh
. "$SELF_DIR/scripts/frontmatter.sh"

usage() {
	cat <<-EOF
		usage: install.sh <target...> [options]
		       install.sh --list
		       install.sh --doctor [target...]
		       install.sh --uninstall <target...> [--only NAMES]

		Targets (at least one required for anything that writes):
		  --claude          \${CLAUDE_CONFIG_DIR:-\$HOME/.claude}/skills/
		  --cursor          \$HOME/.cursor/skills/
		  --agents          \$HOME/.agents/skills/

		Options:
		  --only NAMES      comma-separated skills to act on
		  --exclude NAMES   comma-separated skills to skip
		  --copy            real copies instead of symlinks
		  --dry-run         print the plan, touch nothing
		  --force           replace an entry this script does not own
		  -h, --help        this text

		Modes:
		  --list            skills in this repo, with descriptions
		  --doctor          audit what is installed; exits non-zero if anything is BROKEN
		  --uninstall       remove only what this script installed

		Ownership: a symlink is ours when it points inside this repo's skills/. A --copy
		records its origin in a $MARKER file. Anything else is reported as foreign and
		left strictly alone.
	EOF
}

die() {
	printf 'install.sh: %s\n\n' "$1" >&2
	usage >&2
	exit 2
}

# --- argument parsing ------------------------------------------------------

targets=""
only=""
exclude=""
mode="install"
copy=0
dry_run=0
force=0

[ "$#" -eq 0 ] && {
	usage >&2
	exit 2
}

while [ "$#" -gt 0 ]; do
	case "$1" in
	--claude) targets="$targets claude" ;;
	--cursor) targets="$targets cursor" ;;
	--agents) targets="$targets agents" ;;
	--only)
		[ "$#" -ge 2 ] || die "--only needs a comma-separated list"
		only="$2"
		shift
		;;
	--exclude)
		[ "$#" -ge 2 ] || die "--exclude needs a comma-separated list"
		exclude="$2"
		shift
		;;
	--copy) copy=1 ;;
	--dry-run) dry_run=1 ;;
	--force) force=1 ;;
	--list) mode="list" ;;
	--doctor) mode="doctor" ;;
	--uninstall) mode="uninstall" ;;
	-h | --help)
		usage
		exit 0
		;;
	*) die "unknown flag: $1" ;;
	esac
	shift
done

# Both filters at once is ambiguous — say which two flags collided rather than
# silently letting one win.
[ -n "$only" ] && [ -n "$exclude" ] && die "--only and --exclude cannot be combined"

# --- target resolution -----------------------------------------------------

# Resolved lazily so an unused target's directory is never created, and never even
# named — a stray mkdir in the wrong tree is the exact surprise this script avoids.
target_dir() {
	case "$1" in
	claude) printf '%s/skills\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ;;
	cursor) printf '%s/.cursor/skills\n' "$HOME" ;;
	agents) printf '%s/.agents/skills\n' "$HOME" ;;
	esac
}

# --- skill selection -------------------------------------------------------

all_skills() {
	find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r d; do
		basename "$d"
	done
}

# Membership test against a space-wrapped list, standing in for an associative array.
in_list() {
	case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Comma-separated -> space-separated.
split_names() {
	printf '%s\n' "$1" | tr ',' ' ' | tr -s ' '
}

known=" $(all_skills | tr '\n' ' ')"

selected=""
if [ -n "$only" ]; then
	for n in $(split_names "$only"); do
		in_list "$n" "$known" || die "--only names '$n', which is not a skill in skills/"
		selected="$selected $n"
	done
else
	skipped=""
	[ -n "$exclude" ] && skipped=" $(split_names "$exclude") "
	for n in $(all_skills); do
		[ -n "$skipped" ] && in_list "$n" "$skipped" && continue
		selected="$selected $n"
	done
	if [ -n "$exclude" ]; then
		for n in $(split_names "$exclude"); do
			in_list "$n" "$known" || die "--exclude names '$n', which is not a skill in skills/"
		done
	fi
fi

# --- ownership -------------------------------------------------------------

# The commit this clone sits on. An empty repo or a plain tarball has none, so record
# `unknown` rather than failing — a copy is still ours, we just cannot age it.
repo_commit() {
	git -C "$SELF_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown\n'
}

# Absolute path a symlink points at, without readlink -f (absent on macOS).
link_target() {
	raw=$(readlink "$1")
	case "$raw" in
	/*) printf '%s\n' "$raw" ;;
	*) printf '%s/%s\n' "$(dirname "$1")" "$raw" ;;
	esac
}

# One of: ours-link, ours-broken, ours-copy, foreign, absent.
classify() {
	path="$1"
	if [ -L "$path" ]; then
		parent=$(dirname "$(link_target "$path")")
		resolved=$(cd "$parent" 2>/dev/null && pwd) || resolved=""
		if [ "$resolved" = "$SKILLS_DIR" ]; then
			[ -e "$path" ] && printf 'ours-link\n' || printf 'ours-broken\n'
		else
			printf 'foreign\n'
		fi
	elif [ -d "$path" ]; then
		if [ "$(marker_field "$path" repo)" = "$SELF_DIR" ]; then
			printf 'ours-copy\n'
		else
			printf 'foreign\n'
		fi
	elif [ -e "$path" ]; then
		printf 'foreign\n'
	else
		printf 'absent\n'
	fi
}

# Read one field out of a copy's marker. Compared with `=`, never with grep: the value is
# a filesystem path, and a path holding [ * or \ would be read as a regex and stop matching
# itself — which made the installer disown its own copies.
marker_field() {
	sed -n "s/^$2=//p" "$1/$MARKER" 2>/dev/null | head -n 1
}

# --- modes -----------------------------------------------------------------

do_list() {
	for n in $selected; do
		desc=$(skill_field "$SKILLS_DIR/$n/SKILL.md" description)
		# One line each: the full description is a paragraph and would bury the names.
		printf '%-24s %.80s\n' "$n" "$desc"
	done
}

do_install() {
	dest=$(target_dir "$1")

	# Pre-flight: refuse the whole run before writing anything. A half-applied install
	# that stops at the first collision is harder to reason about than one that never
	# started.
	blocked=""
	for n in $selected; do
		[ "$(classify "$dest/$n")" = "foreign" ] && blocked="$blocked $n"
	done
	if [ -n "$blocked" ] && [ "$force" -eq 0 ]; then
		printf 'refusing: %s already has entries this script does not own:\n' "$dest" >&2
		for n in $blocked; do printf '  %s\n' "$n" >&2; done
		printf 'Re-run with --force to replace them.\n' >&2
		return 1
	fi

	for n in $blocked; do
		printf 'replacing foreign entry: %s/%s\n' "$dest" "$n"
	done

	orphans=""
	for entry in "$dest"/*; do
		[ -L "$entry" ] || continue
		n=$(basename "$entry")
		in_list "$n" "$known" && continue
		[ "$(classify "$entry")" = "ours-broken" ] && orphans="$orphans $n"
	done
	if [ -n "$orphans" ]; then
		printf 'note: %s no longer in this repo, left dangling —' "$dest" >&2
		printf '%s\n' "$orphans" >&2
		printf '      clear with: install.sh --uninstall <target>\n' >&2
	fi

	if [ "$dry_run" -eq 1 ]; then
		printf 'would install into %s:\n' "$dest"
		for n in $selected; do printf '  %s\n' "$n"; done
		return 0
	fi

	mkdir -p "$dest"
	commit=$(repo_commit)
	for n in $selected; do
		rm -rf "${dest:?}/${n:?}"
		if [ "$copy" -eq 1 ]; then
			cp -R "$SKILLS_DIR/$n" "$dest/$n"
			cat >"$dest/$n/$MARKER" <<-EOF
				repo=$SELF_DIR
				commit=$commit
				skill=$n
			EOF
		else
			ln -s "$SKILLS_DIR/$n" "$dest/$n"
		fi
	done
	printf 'installed %s skills into %s\n' "$(printf '%s' "$selected" | wc -w | tr -d ' ')" "$dest"
}

do_doctor() {
	dest=$(target_dir "$1")
	printf '%s\n' "$dest"
	if [ ! -d "$dest" ]; then
		printf '  (not present)\n'
		return 0
	fi

	commit=$(repo_commit)
	broken=0
	present=""

	for entry in "$dest"/*; do
		[ -e "$entry" ] || [ -L "$entry" ] || continue
		n=$(basename "$entry")
		present="$present $n"
		case "$(classify "$entry")" in
		ours-link) printf '  ok        %-22s -> %s\n' "$n" "$(link_target "$entry")" ;;
		ours-broken)
			printf '  BROKEN    %-22s -> dangling (clone moved or deleted?)\n' "$n"
			broken=1
			;;
		ours-copy)
			was=$(marker_field "$entry" commit)
			if [ "$was" != "$commit" ] && [ "$was" != "unknown" ] && [ "$commit" != "unknown" ]; then
				printf '  stale     %-22s copy from %s, repo is at %s\n' "$n" "$was" "$commit"
			else
				printf '  ok        %-22s copy from %s\n' "$n" "$was"
			fi
			;;
		*) printf '  foreign   %-22s not managed by this repo — untouched\n' "$n" ;;
		esac
	done

	for n in $selected; do
		in_list "$n" " $present " && continue
		printf '  missing   %-22s in repo, not installed here\n' "$n"
	done

	return "$broken"
}

do_uninstall() {
	dest=$(target_dir "$1")
	if [ ! -d "$dest" ]; then
		printf '%s: nothing installed\n' "$dest"
		return 0
	fi

	removed=0
	for n in $selected; do
		case "$(classify "$dest/$n")" in
		ours-link | ours-broken | ours-copy)
			if [ "$dry_run" -eq 1 ]; then
				printf 'would remove %s/%s\n' "$dest" "$n"
			else
				rm -rf "${dest:?}/${n:?}"
			fi
			removed=$((removed + 1))
			;;
		foreign) printf 'sparing foreign entry: %s/%s\n' "$dest" "$n" ;;
		esac
	done

	# Sweep orphans: a skill deleted from the repo leaves a link nothing else can clean,
	# because the loop above only walks skills that still exist. The link points into our
	# skills/ and resolves to nothing, so it is ours and it is dead. Skipped under --only,
	# which asked for a specific list and should not quietly remove more than it named.
	if [ -z "$only" ]; then
		for entry in "$dest"/*; do
			[ -L "$entry" ] || continue
			n=$(basename "$entry")
			in_list "$n" " $selected " && continue
			[ "$(classify "$entry")" = "ours-broken" ] || continue
			if [ "$dry_run" -eq 1 ]; then
				printf 'would remove orphan %s/%s (no longer in this repo)\n' "$dest" "$n"
			else
				rm -rf "${dest:?}/${n:?}"
			fi
			printf 'removed orphan: %s (no longer in this repo)\n' "$n"
			removed=$((removed + 1))
		done
	fi

	printf 'removed %s from %s\n' "$removed" "$dest"
	# Leave the directory itself: stow and the agents themselves may rely on it existing.
}

# --- dispatch --------------------------------------------------------------

case "$mode" in
list)
	do_list
	exit 0
	;;
doctor)
	# An audit reads nothing but the filesystem, so it may run with no target: check
	# every place we know how to install to, skipping the ones that do not exist.
	[ -z "$targets" ] && targets="claude cursor agents"
	rc=0
	for t in $targets; do
		do_doctor "$t" || rc=1
	done
	exit "$rc"
	;;
esac

[ -n "$targets" ] || die "no target given — name at least one of --claude, --cursor, --agents"

rc=0
for t in $targets; do
	case "$mode" in
	install) do_install "$t" || rc=1 ;;
	uninstall) do_uninstall "$t" || rc=1 ;;
	esac
done
exit "$rc"
