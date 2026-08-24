#!/usr/bin/env bash
# Read, parse, and write the plugin version — the one place any version string is derived.
#
# .claude-plugin/plugin.json is the single source of truth for the version the marketplace
# advertises, and a version that never moves leaves installed users pinned to the old copy.
# That failure is silent, which is why the release workflow calls --set instead of editing
# the field inline: the rules below (never backwards, re-runs are no-ops) are testable here
# and would not be testable in YAML.
#
# Usage: scripts/version.sh                    print the version in the manifest
#        scripts/version.sh --parse-tag TAG    print the version a release tag names
#        scripts/version.sh --set VERSION      rewrite the manifest's version field
#
# Set PLUGIN_MANIFEST to point at a different manifest; the tests use it.
#
# Targets bash 3.2 so it runs on stock macOS: no associative arrays, no mapfile.

set -euo pipefail

MANIFEST="${PLUGIN_MANIFEST:-$(dirname "$0")/../.claude-plugin/plugin.json}"

SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'

die() {
	printf 'version.sh: %s\n' "$*" >&2
	exit 1
}

is_semver() {
	printf '%s' "$1" | grep -Eq "$SEMVER_RE"
}

# The manifest is flat and hand-written, so a grep is enough and keeps this script free of a
# JSON dependency the rest of scripts/ does not have. Anything other than exactly one match
# means the file was reshaped and the grep can no longer be trusted to find the right line.
read_version() {
	_hits=$(grep -c '^[[:space:]]*"version"[[:space:]]*:' "$MANIFEST" || true)
	[ "$_hits" = 1 ] || die "expected exactly one \"version\" line in $MANIFEST, found $_hits"
	sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST"
}

# Accepts every shape a release tag has worn here: a bare 0.2.0, the v0.2.0 this repo has
# used, and the <plugin-name>--v0.2.0 form `claude plugin tag` produces. Stripping up to the
# last --v keeps this working whatever the plugin is called.
parse_tag() {
	_tag=$1
	_v=${_tag##*--v}
	_v=${_v#v}
	is_semver "$_v" || die "tag \"$_tag\" does not name a semver version"
	printf '%s\n' "$_v"
}

# Prints 1, 0, or -1 for a>b, a==b, a<b, comparing only the numeric core. A pre-release
# suffix never decides ordering here — it only decides whether two versions with the same
# core are the same string, which set_version checks separately.
compare_core() {
	_a=${1%%[-+]*}
	_b=${2%%[-+]*}
	_i=1
	while [ "$_i" -le 3 ]; do
		_x=$(printf '%s' "$_a" | cut -d. -f"$_i")
		_y=$(printf '%s' "$_b" | cut -d. -f"$_i")
		[ "$_x" -gt "$_y" ] && { printf '1\n'; return; }
		[ "$_x" -lt "$_y" ] && { printf -- '-1\n'; return; }
		_i=$((_i + 1))
	done
	printf '0\n'
}

set_version() {
	_new=$1
	is_semver "$_new" || die "\"$_new\" is not a semver version"
	_cur=$(read_version)
	is_semver "$_cur" || die "manifest version \"$_cur\" is not semver; fix it by hand"

	# A re-run of the release workflow must be harmless, so landing on the version already
	# there is success with nothing written, not an error.
	if [ "$_cur" = "$_new" ]; then
		printf 'version.sh: already at %s, nothing to write\n' "$_new"
		return 0
	fi

	[ "$(compare_core "$_new" "$_cur")" = '-1' ] &&
		die "refusing to move the version backwards: $_cur -> $_new"

	# Write through a temp file rather than sed -i, whose in-place flag takes an argument on
	# BSD sed and none on GNU sed.
	_tmp="$MANIFEST.tmp.$$"
	sed 's|^\([[:space:]]*"version"[[:space:]]*:[[:space:]]*"\)[^"]*|\1'"$_new"'|' "$MANIFEST" >"$_tmp"
	mv "$_tmp" "$MANIFEST"
	printf 'version.sh: %s -> %s\n' "$_cur" "$_new"
}

case "${1:-}" in
'') read_version ;;
--parse-tag)
	[ "$#" -eq 2 ] || die "--parse-tag needs exactly one tag"
	parse_tag "$2"
	;;
--set)
	[ "$#" -eq 2 ] || die "--set needs exactly one version"
	set_version "$2"
	;;
-h | --help) sed -n '2,14p' "$0" ;;
*) die "unknown argument: $1" ;;
esac
