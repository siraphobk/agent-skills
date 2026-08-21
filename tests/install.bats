#!/usr/bin/env bats
#
# install.sh is branching logic — target selection, filtering, ownership, refusal —
# so it gets tested rather than eyeballed. Every case runs against a throwaway HOME.

load helpers

setup() {
	setup_sandbox
}

# --- no target -------------------------------------------------------------

@test "no arguments prints usage and exits non-zero" {
	run "$INSTALL"
	[ "$status" -ne 0 ]
	[[ "$output" == *"usage"* ]]
}

@test "a flag without a target still refuses to guess" {
	run "$INSTALL" --copy
	[ "$status" -ne 0 ]
	[[ "$output" == *"target"* ]]
	[ ! -d "$HOME/.claude" ]
	[ ! -d "$HOME/.cursor" ]
	[ ! -d "$HOME/.agents" ]
}

@test "an unknown flag is rejected" {
	run "$INSTALL" --claude --frobnicate
	[ "$status" -ne 0 ]
	[[ "$output" == *"frobnicate"* ]]
}

# --- read-only modes -------------------------------------------------------

@test "--list names every skill and writes nothing" {
	run "$INSTALL" --list
	[ "$status" -eq 0 ]
	[[ "$output" == *"$(first_skill)"* ]]
	[[ "$output" == *"$(second_skill)"* ]]
	[ ! -d "$HOME/.claude" ]
}

# Most skills here write their description as a YAML folded scalar (`description: >`).
# A one-line reader returns the `>` marker instead of the text, which looks like a
# working description to anything that only checks for non-empty.
@test "--list shows real descriptions, not the folded-scalar marker" {
	run "$INSTALL" --list
	[ "$status" -eq 0 ]
	bad=""
	# A here-string is not a pipeline, so `bad` survives the loop.
	while IFS= read -r line; do
		desc="${line:25}"
		case "$desc" in ">"* | "|"* | "") bad="$bad $line" ;; esac
		[ "${#desc}" -ge 20 ] || bad="$bad $line"
	done <<<"$output"
	[ -z "$bad" ] || {
		printf 'unreadable descriptions:%s\n' "$bad"
		false
	}
}

@test "--dry-run prints the plan and creates nothing" {
	run "$INSTALL" --claude --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *"$(first_skill)"* ]]
	[ ! -e "$HOME/.claude/skills/$(first_skill)" ]
}

# --- target selection ------------------------------------------------------

@test "--claude links into ~/.claude/skills" {
	run "$INSTALL" --claude
	[ "$status" -eq 0 ]
	[ -L "$HOME/.claude/skills/$(first_skill)" ]
	[ "$(find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" = "$(skill_count)" ]
}

@test "--claude honours CLAUDE_CONFIG_DIR" {
	export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/altconfig"
	run "$INSTALL" --claude
	[ "$status" -eq 0 ]
	[ -L "$CLAUDE_CONFIG_DIR/skills/$(first_skill)" ]
	[ ! -d "$HOME/.claude/skills" ]
}

@test "--cursor links into ~/.cursor/skills" {
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	[ -L "$HOME/.cursor/skills/$(first_skill)" ]
}

@test "--agents links into ~/.agents/skills" {
	run "$INSTALL" --agents
	[ "$status" -eq 0 ]
	[ -L "$HOME/.agents/skills/$(first_skill)" ]
}

@test "two targets in one run install to both" {
	run "$INSTALL" --claude --cursor
	[ "$status" -eq 0 ]
	[ -L "$HOME/.claude/skills/$(first_skill)" ]
	[ -L "$HOME/.cursor/skills/$(first_skill)" ]
}

# --- filtering -------------------------------------------------------------

@test "--only installs exactly the named skills" {
	a="$(first_skill)"; b="$(second_skill)"
	run "$INSTALL" --cursor --only "$a,$b"
	[ "$status" -eq 0 ]
	[ -L "$HOME/.cursor/skills/$a" ]
	[ -L "$HOME/.cursor/skills/$b" ]
	[ "$(find "$HOME/.cursor/skills" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" = "2" ]
}

@test "--exclude installs everything else" {
	a="$(first_skill)"
	run "$INSTALL" --cursor --exclude "$a"
	[ "$status" -eq 0 ]
	[ ! -e "$HOME/.cursor/skills/$a" ]
	[ -L "$HOME/.cursor/skills/$(second_skill)" ]
}

@test "--only with a name that is not a skill fails loudly" {
	run "$INSTALL" --cursor --only nonexistent-skill
	[ "$status" -ne 0 ]
	[[ "$output" == *"nonexistent-skill"* ]]
	[ ! -d "$HOME/.cursor/skills" ]
}

@test "--only and --exclude together is rejected" {
	run "$INSTALL" --cursor --only "$(first_skill)" --exclude "$(second_skill)"
	[ "$status" -ne 0 ]
	[[ "$output" == *"--only"* ]]
	[[ "$output" == *"--exclude"* ]]
}

# --- symlink vs copy -------------------------------------------------------

@test "default install is a symlink back into this repo" {
	a="$(first_skill)"
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	[ -L "$HOME/.cursor/skills/$a" ]
	[ "$(cd "$(dirname "$(readlink "$HOME/.cursor/skills/$a")")" && pwd)" = "$REPO_ROOT/skills" ]
}

@test "--copy writes real directories with an ownership marker" {
	a="$(first_skill)"
	run "$INSTALL" --cursor --copy
	[ "$status" -eq 0 ]
	[ ! -L "$HOME/.cursor/skills/$a" ]
	[ -d "$HOME/.cursor/skills/$a" ]
	[ -f "$HOME/.cursor/skills/$a/SKILL.md" ]
	[ -f "$HOME/.cursor/skills/$a/.installed-from" ]
	grep -q "$REPO_ROOT" "$HOME/.cursor/skills/$a/.installed-from"
}

@test "installing twice is idempotent" {
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	[ "$(find "$HOME/.cursor/skills" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" = "$(skill_count)" ]
}

# --- refusing to clobber ---------------------------------------------------

@test "a foreign entry blocks the install and survives untouched" {
	a="$(first_skill)"
	plant_foreign "$HOME/.cursor/skills/$a"
	run "$INSTALL" --cursor
	[ "$status" -ne 0 ]
	[[ "$output" == *"$a"* ]]
	[ ! -L "$HOME/.cursor/skills/$a" ]
	grep -q "mine, not yours" "$HOME/.cursor/skills/$a/SKILL.md"
}

@test "--force replaces a foreign entry and says what it replaced" {
	a="$(first_skill)"
	plant_foreign "$HOME/.cursor/skills/$a"
	run "$INSTALL" --cursor --force
	[ "$status" -eq 0 ]
	[[ "$output" == *"$a"* ]]
	[ -L "$HOME/.cursor/skills/$a" ]
}

@test "replacing our own entry needs no --force" {
	run "$INSTALL" --cursor --copy
	[ "$status" -eq 0 ]
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	[ -L "$HOME/.cursor/skills/$(first_skill)" ]
}

# --- doctor ----------------------------------------------------------------

@test "doctor reports ok for a live symlink" {
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	run "$INSTALL" --doctor --cursor
	[ "$status" -eq 0 ]
	[[ "$output" == *"ok"* ]]
	[[ "$output" == *"$(first_skill)"* ]]
}

@test "doctor reports BROKEN for a dangling symlink" {
	a="$(first_skill)"
	mkdir -p "$HOME/.cursor/skills"
	ln -s "$REPO_ROOT/skills/gone-away" "$HOME/.cursor/skills/$a"
	run "$INSTALL" --doctor --cursor
	[[ "$output" == *"BROKEN"* ]]
	[[ "$output" == *"$a"* ]]
}

@test "doctor reports foreign for something we did not install" {
	plant_foreign "$HOME/.cursor/skills/my-own-thing"
	run "$INSTALL" --doctor --cursor
	[[ "$output" == *"foreign"* ]]
	[[ "$output" == *"my-own-thing"* ]]
}

@test "doctor reports missing for a skill in the repo but not installed" {
	a="$(first_skill)"
	run "$INSTALL" --cursor --only "$(second_skill)"
	[ "$status" -eq 0 ]
	run "$INSTALL" --doctor --cursor
	[[ "$output" == *"missing"* ]]
	[[ "$output" == *"$a"* ]]
}

@test "doctor reports stale when a copy predates the current commit" {
	fixture="$(make_fixture_repo)"
	run "$fixture/install.sh" --cursor --copy
	[ "$status" -eq 0 ]
	sed -i.bak 's/^commit=.*/commit=0000000/' "$HOME/.cursor/skills/alpha/.installed-from"
	rm -f "$HOME/.cursor/skills/alpha/.installed-from.bak"
	run "$fixture/install.sh" --doctor --cursor
	[[ "$output" == *"stale"* ]]
	[[ "$output" == *"alpha"* ]]
}

@test "doctor with no target audits every target directory that exists" {
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	run "$INSTALL" --doctor
	[ "$status" -eq 0 ]
	[[ "$output" == *".cursor/skills"* ]]
}

# --- uninstall -------------------------------------------------------------

@test "uninstall removes our symlinks" {
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	run "$INSTALL" --uninstall --cursor
	[ "$status" -eq 0 ]
	[ ! -e "$HOME/.cursor/skills/$(first_skill)" ]
}

@test "uninstall removes our copies via the marker" {
	a="$(first_skill)"
	run "$INSTALL" --cursor --copy
	[ "$status" -eq 0 ]
	run "$INSTALL" --uninstall --cursor
	[ "$status" -eq 0 ]
	[ ! -e "$HOME/.cursor/skills/$a" ]
}

@test "uninstall spares a foreign entry" {
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	plant_foreign "$HOME/.cursor/skills/my-own-thing"
	run "$INSTALL" --uninstall --cursor
	[ "$status" -eq 0 ]
	[ -f "$HOME/.cursor/skills/my-own-thing/SKILL.md" ]
	[ ! -e "$HOME/.cursor/skills/$(first_skill)" ]
}

# A skill deleted from the repo leaves a link that the normal uninstall loop cannot see,
# because that loop only walks skills which still exist.
@test "uninstall sweeps a link left behind by a skill removed from the repo" {
	fixture="$(make_fixture_repo)"
	run "$fixture/install.sh" --cursor
	[ "$status" -eq 0 ]
	[ -L "$HOME/.cursor/skills/beta" ]
	rm -rf "$fixture/skills/beta"
	run "$fixture/install.sh" --uninstall --cursor
	[ "$status" -eq 0 ]
	[[ "$output" == *"orphan"* ]]
	[ ! -L "$HOME/.cursor/skills/alpha" ]
	[ ! -L "$HOME/.cursor/skills/beta" ]
}

@test "uninstall --only does not sweep orphans it was not asked about" {
	fixture="$(make_fixture_repo)"
	run "$fixture/install.sh" --cursor
	[ "$status" -eq 0 ]
	rm -rf "$fixture/skills/beta"
	run "$fixture/install.sh" --uninstall --cursor --only alpha
	[ "$status" -eq 0 ]
	[ ! -L "$HOME/.cursor/skills/alpha" ]
	[ -L "$HOME/.cursor/skills/beta" ]
}

@test "install warns about a link left behind by a removed skill" {
	fixture="$(make_fixture_repo)"
	run "$fixture/install.sh" --cursor
	[ "$status" -eq 0 ]
	rm -rf "$fixture/skills/beta"
	run "$fixture/install.sh" --cursor
	[ "$status" -eq 0 ]
	[[ "$output" == *"beta"* ]]
	[[ "$output" == *"--uninstall"* ]]
}

@test "uninstall without a target refuses" {
	run "$INSTALL" --uninstall
	[ "$status" -ne 0 ]
	[[ "$output" == *"target"* ]]
}

@test "uninstall --only removes just those" {
	a="$(first_skill)"; b="$(second_skill)"
	run "$INSTALL" --cursor
	[ "$status" -eq 0 ]
	run "$INSTALL" --uninstall --cursor --only "$a"
	[ "$status" -eq 0 ]
	[ ! -e "$HOME/.cursor/skills/$a" ]
	[ -L "$HOME/.cursor/skills/$b" ]
}
