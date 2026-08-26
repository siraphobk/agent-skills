#!/usr/bin/env bats
#
# validate.sh is the only thing standing between a malformed skill and a skill that
# silently stops triggering. Every check below is proved to FIRE on bad input — a suite
# that only confirms good input passes cannot tell a working check from a dead one.
#
# Each test builds its own throwaway skills/ tree, so none of them depend on the state
# of the repo's real skills.

load helpers

setup() {
	SKILLS="$(new_skills_dir)"
	write_skill "$SKILLS" alpha
}

# --- the happy path --------------------------------------------------------

@test "a well-formed skill passes" {
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ok"* ]]
}

# --- structure -------------------------------------------------------------

@test "a skill folder with no SKILL.md fails" {
	mkdir -p "$SKILLS/beta"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no SKILL.md"* ]]
}

@test "a SKILL.md with no frontmatter block fails" {
	printf '# alpha\n\nno frontmatter here\n' >"$SKILLS/alpha/SKILL.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"frontmatter"* ]]
}

@test "a missing name fails" {
	drop_field "$SKILLS/alpha/SKILL.md" name
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no 'name'"* ]]
}

# Cursor rejects the skill outright when these disagree, so this one matters most.
@test "a name that does not match the folder fails" {
	set_field "$SKILLS/alpha/SKILL.md" name notalpha
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"does not match folder"* ]]
}

# --- description -----------------------------------------------------------

@test "a missing description fails" {
	drop_field "$SKILLS/alpha/SKILL.md" description
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no 'description'"* ]]
}

# A folded scalar with nothing under it reads as `>` to a one-line parser, which is
# non-empty — so a naive present-check would pass a skill with no description at all.
@test "an empty folded description fails" {
	printf -- '---\nname: alpha\nallowed-tools: Read\ndescription: >\n---\n\n# alpha\n' \
		>"$SKILLS/alpha/SKILL.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no 'description'"* ]]
}

@test "a description over the limit fails" {
	long=$(head -c 1100 /dev/zero | tr '\0' 'x')
	set_field "$SKILLS/alpha/SKILL.md" description "$long"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"over the 1024 limit"* ]]
}

@test "a description just under the limit passes" {
	long=$(head -c 1000 /dev/zero | tr '\0' 'x')
	set_field "$SKILLS/alpha/SKILL.md" description "$long"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# --- size ------------------------------------------------------------------

@test "a SKILL.md at or over the line limit fails" {
	for i in $(seq 1 200); do printf 'padding line %s\n' "$i"; done >>"$SKILLS/alpha/SKILL.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"move overflow to a bundled file"* ]]
}

# --- allowed-tools ---------------------------------------------------------

@test "a missing allowed-tools fails" {
	drop_field "$SKILLS/alpha/SKILL.md" allowed-tools
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no 'allowed-tools'"* ]]
}

# The skill tells the agent to open a bundled file; without Read that is a refused tool
# call partway through a run, not an error anyone sees up front.
@test "bundling a file without Read in allowed-tools fails" {
	printf '# notes\n' >"$SKILLS/alpha/NOTES.md"
	set_field "$SKILLS/alpha/SKILL.md" allowed-tools "Bash(gh *)"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no Read"* ]]
}

@test "bundling a file with Read in allowed-tools passes" {
	printf '# notes\n' >"$SKILLS/alpha/NOTES.md"
	set_field "$SKILLS/alpha/SKILL.md" allowed-tools "Read Bash(gh *)"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# --- links -----------------------------------------------------------------

@test "a relative link to a file that does not exist fails" {
	write_skill "$SKILLS" beta "See [notes](NOTES.md) for more."
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"broken link"* ]]
}

@test "a relative link that resolves passes" {
	write_skill "$SKILLS" beta "See [notes](NOTES.md) for more."
	printf '# notes\n' >"$SKILLS/beta/NOTES.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# Skills routinely show example paths in fenced blocks. Treating those as links would
# make every worked example a failure.
@test "a link inside a fenced code block is not treated as a link" {
	write_skill "$SKILLS" beta '```
see [notes](does-not-exist.md)
```'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# --- host-specific paths ---------------------------------------------------

@test "a host-specific path fails" {
	write_skill "$SKILLS" beta 'Write the report to .claude/scratch/reports/.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"host-specific path"* ]]
}

@test "a home-directory agent path fails" {
	write_skill "$SKILLS" beta 'Edit ~/.cursor/rules/topic.mdc when done.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"host-specific path"* ]]
}

@test "the neutral state directory is not flagged" {
	write_skill "$SKILLS" beta 'Write to ~/.agent-skills/<encoded-root>/handoffs/.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# Naming per-agent locations is that file's whole job, so it is exempt by path.
@test "AGENT-STRATEGIES.md may name agent paths" {
	write_skill "$SKILLS" self-improve "See [strategies](AGENT-STRATEGIES.md)."
	printf '# per agent\n\nWrite to ~/.claude/rules/topic.md.\n' \
		>"$SKILLS/self-improve/AGENT-STRATEGIES.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

@test "every exempt path is exempt, not just the first" {
	write_skill "$SKILLS" where-am-i "See [strategies](AGENT-STRATEGIES.md)."
	printf '# per agent\n\nRead the transcript under ~/.claude/projects/.\n' \
		>"$SKILLS/where-am-i/AGENT-STRATEGIES.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# The exemption is by path, so the filename alone must not buy a way out of the check —
# otherwise any skill opts out by naming a file AGENT-STRATEGIES.md.
@test "AGENT-STRATEGIES.md in a skill that is not exempt still fails" {
	write_skill "$SKILLS" beta "See [strategies](AGENT-STRATEGIES.md)."
	printf '# per agent\n\nWrite to ~/.claude/rules/topic.md.\n' \
		>"$SKILLS/beta/AGENT-STRATEGIES.md"
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"host-specific path"* ]]
}

# --- dangling skill references ---------------------------------------------

@test "pointing at a skill that is not in the tree fails" {
	write_skill "$SKILLS" beta 'Hand off to `some-other-skill` when done.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"some-other-skill"* ]]
}

@test "pointing at a skill that is in the tree passes" {
	write_skill "$SKILLS" beta 'Hand off to `alpha` when done.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

@test "naming a deliberately dropped skill fails" {
	write_skill "$SKILLS" beta 'Hand off to `remember`; it owns the write.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"dropped skill"* ]]
}

@test "the unbackticked reference form is caught too" {
	write_skill "$SKILLS" beta 'NOT for saving a single fact (use remember).'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -ne 0 ]
	[[ "$output" == *"dropped skill"* ]]
}

# `remember` is also an ordinary English word. Firing on it in prose would make the
# check unusable, since trigger lines legitimately say things like this.
@test "the same word in plain prose is not flagged" {
	write_skill "$SKILLS" beta 'Use when the user asks what you should remember from this.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

@test "an allowlisted external tool is not read as a skill" {
	write_skill "$SKILLS" beta 'Needs the `gh-stack` extension; use `link`, never `submit`.'
	run "$VALIDATE" "$SKILLS"
	[ "$status" -eq 0 ]
}

# --- invocation ------------------------------------------------------------

@test "a missing skills directory is an error, not a pass" {
	run "$VALIDATE" "$BATS_TEST_TMPDIR/nope"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no such directory"* ]]
}
