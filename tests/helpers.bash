# Shared setup for the install.sh suite.
#
# Every test runs against a throwaway HOME so nothing can touch real agent config.
# Targets bash 3.2 like install.sh itself: no associative arrays, no mapfile.

# Absolute path to the repo under test.
REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INSTALL="$REPO_ROOT/install.sh"

# Point HOME at a directory that only this test can see, and clear the one env var
# that would otherwise redirect --claude somewhere real.
setup_sandbox() {
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME"
	unset CLAUDE_CONFIG_DIR
}

# A skill name that exists in this repo, for tests that need a real one.
# Picked at runtime so renaming a skill does not silently skip a test.
first_skill() {
	basename "$(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | sort | head -n 1)"
}

second_skill() {
	basename "$(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | sort | sed -n 2p)"
}

skill_count() {
	find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
}

# Plant a directory the installer does not own, to prove it is left alone.
plant_foreign() {
	dir="$1"
	mkdir -p "$dir"
	printf 'mine, not yours\n' >"$dir/SKILL.md"
}

# A self-contained repo with real git history, for the checks that compare a recorded
# commit against the current one. The repo under test may have no commits yet, and a
# `stale` verdict is meaningless without two shas to compare.
make_fixture_repo() {
	fixture="$BATS_TEST_TMPDIR/fixture"
	mkdir -p "$fixture/skills/alpha" "$fixture/skills/beta"
	cp "$INSTALL" "$fixture/install.sh"
	# install.sh sources its frontmatter reader from a sibling directory.
	mkdir -p "$fixture/scripts"
	cp "$REPO_ROOT/scripts/frontmatter.sh" "$fixture/scripts/frontmatter.sh"
	for n in alpha beta; do
		cat >"$fixture/skills/$n/SKILL.md" <<-EOF
			---
			name: $n
			description: fixture skill $n
			---
		EOF
	done
	git -C "$fixture" init --quiet
	git -C "$fixture" -c user.email=t@t -c user.name=t add -A
	git -C "$fixture" -c user.email=t@t -c user.name=t commit --quiet -m init
	printf '%s\n' "$fixture"
}

# --- validate.sh fixtures ---------------------------------------------------

# shellcheck disable=SC2034  # consumed by validate.bats, not by this file
VALIDATE="$REPO_ROOT/scripts/validate.sh"

# A throwaway skills/ tree to point validate.sh at, so a test never depends on the
# repo's real skills passing or failing.
new_skills_dir() {
	printf '%s\n' "$BATS_TEST_TMPDIR/skills"
}

# write_skill <skills-dir> <name> [body-after-frontmatter]
# A minimal skill that passes every check, for tests to break one field at a time.
write_skill() {
	_sdir=$1
	_name=$2
	_body=${3:-"Body."}
	mkdir -p "$_sdir/$_name"
	{
		printf -- '---\n'
		printf 'name: %s\n' "$_name"
		printf 'allowed-tools: Read Write\n'
		printf 'description: does a thing worth testing\n'
		printf -- '---\n\n'
		printf '# %s\n\n' "$_name"
		printf '%s\n' "$_body"
	} >"$_sdir/$_name/SKILL.md"
}

# Replace one frontmatter line in an existing fixture skill.
set_field() {
	_file=$1
	_field=$2
	_value=$3
	sed -i.bak "s|^$_field:.*|$_field: $_value|" "$_file"
	rm -f "$_file.bak"
}

drop_field() {
	sed -i.bak "/^$2:/d" "$1"
	rm -f "$1.bak"
}
