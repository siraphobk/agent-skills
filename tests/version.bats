#!/usr/bin/env bats
#
# version.sh is the only thing that reads or writes the version the marketplace advertises,
# and a version that quietly fails to move leaves every installed user pinned to the old
# copy — the exact bug this script exists to prevent. So every check below is proved to FIRE
# on bad input; a suite that only confirms good input passes cannot tell a working check from
# a dead one.
#
# Each test builds its own throwaway manifest, so none of them can touch the repo's real one.

load helpers

VERSION="$REPO_ROOT/scripts/version.sh"

setup() {
	export PLUGIN_MANIFEST="$BATS_TEST_TMPDIR/plugin.json"
	cat >"$PLUGIN_MANIFEST" <<-'EOF'
		{
		  "name": "agent-skills",
		  "version": "0.1.2",
		  "author": {
		    "name": "siraphobk"
		  }
		}
	EOF
	cp "$PLUGIN_MANIFEST" "$BATS_TEST_TMPDIR/before.json"
}

# The manifest must come out byte-identical whenever a write was refused or skipped.
assert_unchanged() {
	cmp -s "$PLUGIN_MANIFEST" "$BATS_TEST_TMPDIR/before.json"
}

# --- reading ---------------------------------------------------------------

@test "prints the version in the manifest" {
	run "$VERSION"
	[ "$status" -eq 0 ]
	[ "$output" = "0.1.2" ]
}

@test "a manifest with no version line fails" {
	grep -v '"version"' "$BATS_TEST_TMPDIR/before.json" >"$PLUGIN_MANIFEST"
	run "$VERSION"
	[ "$status" -ne 0 ]
	[[ "$output" == *"found 0"* ]]
}

@test "a manifest with two version lines fails" {
	sed 's|"version": "0.1.2",|"version": "0.1.2",\n  "version": "9.9.9",|' \
		"$BATS_TEST_TMPDIR/before.json" >"$PLUGIN_MANIFEST"
	run "$VERSION"
	[ "$status" -ne 0 ]
	[[ "$output" == *"found 2"* ]]
}

# --- parsing a release tag -------------------------------------------------

@test "--parse-tag accepts every tag shape this repo has used" {
	for tag in 0.2.0 v0.2.0 agent-skills--v0.2.0; do
		run "$VERSION" --parse-tag "$tag"
		[ "$status" -eq 0 ]
		[ "$output" = "0.2.0" ]
	done
}

@test "--parse-tag keeps a pre-release suffix" {
	run "$VERSION" --parse-tag v0.1.3-test
	[ "$status" -eq 0 ]
	[ "$output" = "0.1.3-test" ]
}

@test "--parse-tag rejects a tag that is not a version" {
	for tag in nightly release-2024 v1.2 ""; do
		run "$VERSION" --parse-tag "$tag"
		[ "$status" -ne 0 ]
	done
}

@test "--parse-tag with no tag fails" {
	run "$VERSION" --parse-tag
	[ "$status" -ne 0 ]
}

# --- writing ---------------------------------------------------------------

@test "--set to a higher version rewrites only the version line" {
	run "$VERSION" --set 0.2.0
	[ "$status" -eq 0 ]
	[[ "$output" == *"0.1.2 -> 0.2.0"* ]]
	[ "$("$VERSION")" = "0.2.0" ]
	# Exactly one line differs between before and after.
	[ "$(diff "$BATS_TEST_TMPDIR/before.json" "$PLUGIN_MANIFEST" | grep -c '^[<>]')" -eq 2 ]
}

@test "--set to a pre-release ahead of the current version is allowed" {
	run "$VERSION" --set 0.1.3-test
	[ "$status" -eq 0 ]
	[ "$("$VERSION")" = "0.1.3-test" ]
}

@test "--set to the version already there writes nothing and succeeds" {
	run "$VERSION" --set 0.1.2
	[ "$status" -eq 0 ]
	[[ "$output" == *"nothing to write"* ]]
	assert_unchanged
}

@test "--set to a lower version fails and leaves the manifest alone" {
	run "$VERSION" --set 0.1.1
	[ "$status" -ne 0 ]
	[[ "$output" == *"backwards"* ]]
	assert_unchanged
}

@test "--set to a lower minor fails even when the patch is higher" {
	run "$VERSION" --set 0.0.9
	[ "$status" -ne 0 ]
	assert_unchanged
}

@test "--set to something that is not a version fails" {
	for v in nightly 1.2 "" 0.1.2.3; do
		run "$VERSION" --set "$v"
		[ "$status" -ne 0 ]
		assert_unchanged
	done
}

@test "--set with no version fails" {
	run "$VERSION" --set
	[ "$status" -ne 0 ]
	assert_unchanged
}

# --- dispatch --------------------------------------------------------------

@test "an unknown argument fails" {
	run "$VERSION" --bump
	[ "$status" -ne 0 ]
	[[ "$output" == *"unknown argument"* ]]
}
