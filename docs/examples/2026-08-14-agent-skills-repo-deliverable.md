# Delivered — Build the agent-skills repo and migrate off stow

Plan: `.agents/scratch/plans/2026-08-14-agent-skills-repo.md`
Branch: `main`

## Summary

The 16 skills now live in `agent-skills` and install from there; `dot-files` keeps only
`remember` and `work-log`. `~/.claude/skills` is a real directory holding 18 symlinks — 2
into `dot-files`, 16 into `agent-skills` — so both repos can serve the same directory.
Every skill is agent-agnostic: no host-specific path survives outside the one exempt file,
and the shared scratch convention is `.agents/scratch/`. `install.sh` covers Cursor and any
other agent, refuses to touch anything it does not own, and is backed by 32 bats tests.

## Acceptance criteria

| AC | Verdict | Evidence |
|---|---|---|
| AC-1 marketplace install | **not verified** | needs a remote; this clone has no `origin` and no commits |
| AC-2 `--cursor` links all 16 | pass | `--cursor --dry-run` plans 16, skips none |
| AC-3 no absent-skill references | pass | `validate.sh` → `ok (16 skills)` |
| AC-4 name/folder mismatch caught | pass | fixture with `name: wrong-name` → exit 1, names the mismatch |
| AC-5 uninstall spares foreign | pass | `bats tests/` 32/32, including the foreign and uninstall cases |
| AC-6 18 symlinks, 2+16 | pass | `find ~/.claude/skills -maxdepth 1 -type l \| wc -l` → 18 |
| AC-7 no re-fold on a fresh machine | pass | `rm -rf ~/.claude/skills && make stow-claude` → `unfolded`, then restored |
| AC-8 CI runs all three checks | partial | workflow written; all three pass locally, first CI run still needs a remote |
| AC-9 no host-specific paths | pass | `grep` over `skills/` outside `AGENT-STRATEGIES.md` → no matches |
| AC-10 `self-improve` per-agent | **not verified** | manual, and Cursor is not installed on this machine |

## Changes by phase

### [x] Phase 1 — repo scaffolding
Files: `.claude-plugin/marketplace.json` (new), `.claude-plugin/plugin.json` (new),
`.gitignore` (new), `CLAUDE.md` (new)
Gate: `jq empty .claude-plugin/marketplace.json .claude-plugin/plugin.json && echo ok`
→ printed `ok`

### [x] Phase 2 — import the 16 skills
Files: `skills/` (new — 16 directories, 31 files)
Precondition first: committed the 3 pending `github-pr-review` files in `dot-files` as
`94e11ee feat: post full findings as PR inline comments` (+52/−12). Not pushed.
Gate: `ls -1 skills | wc -l` → `16`; `find skills -type f | wc -l` → `31`;
`ls skills/remember skills/work-log` → both "No such file or directory".
Extra checks: every skill dir has a `SKILL.md`; `github-pr-review/TEMPLATE.md` contains
"Posting keeps this exact shape", confirming the newly committed version was the one imported.

### [x] Phase 3 — `validate.sh`, expected red
Files: `scripts/validate.sh` (new)
Gate: `scripts/validate.sh; echo "exit=$?"` → `exit=1`, reporting 19 host-path hits across
12 skills and 5 dangling references across 4 files; 0 broken links, 0 frontmatter errors.
`shellcheck scripts/validate.sh` → clean.
Also spot-checked AC-4 early: a folder `bad/` whose frontmatter says `name: wrong-name`
is reported and exits 1.

Checks implemented: SKILL.md present; frontmatter block present; `name` matches folder;
`description` non-empty; relative links resolve; no host-specific path (exempting
`self-improve/AGENT-STRATEGIES.md`); no reference to a skill absent from `skills/`.

### [x] Phase 4 — fix the dangling references
Files: `skills/self-improve/SKILL.md` (3 sites), `skills/self-improve/EXAMPLES.md`,
`skills/write-skill/SKILL.md` (3 sites), `skills/execute-plan/SKILL.md`
Gate: ``grep -rn '`remember`\|`work-log`' skills/`` → no matches. `validate.sh`'s
dangling-reference check — stricter, since it also catches the unbackticked `(use remember)`
form — reports none. Exit is still 1 on 19 host-path hits, expected until Phase 7.

What changed:
- `self-improve` brain-fragment branch is now conditional — hand off to a memory skill if one
  is installed, otherwise write the fragment plus its index line inline. Decision: keep the
  destination class rather than drop it.
- `write-skill`'s modes example swapped from `remember` to `analyze-issue`, which is in this
  repo and genuinely has modes (`quick|default|deep`, `bug|feature`).
- `execute-plan:89` and three description clauses restated as behaviour, naming no skill.

### [x] Phase 5 — agent-agnostic state paths
Files: `skills/write-handoff/SKILL.md` (3 sites), `skills/read-handoff/SKILL.md` (2 sites),
`skills/research-solutions/SKILL.md`, `skills/research-solutions/TEMPLATES.md` (added to
scope), `skills/write-skill/SKILL.md` (4 sites)
Gate: `grep -rln 'claude/projects' skills/` → `skills/self-improve/SKILL.md` only.
No `~/.claude` or `~/.cursor` remains outside `self-improve/`. `validate.sh` → exit 1 with
14 hits: 12 `.claude/scratch` (Phase 7) and 2 `self-improve` (Phase 6).

Both handoff skills now build their directory as
`dir=~/.agent-skills/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs`, with the prose and
`write-handoff`'s description updated to match.

### [x] Phase 6 — per-agent strategy for `self-improve`
Files: `skills/self-improve/SKILL.md`, `skills/self-improve/EXAMPLES.md`,
`skills/self-improve/AGENT-STRATEGIES.md` (new)
Gate: `grep -rn 'claude/projects\|~/\.claude\|~/\.cursor' skills/ | grep -v AGENT-STRATEGIES.md`
→ no matches. Both `## Claude Code` and `## Cursor` sections present in the new file.
`validate.sh` → exit 1 with 12 hits, all `.claude/scratch`, which is Phase 7's work.
Workflow steps renumber 1–7 with no stale cross-references; all links resolve.

What changed:
- `SKILL.md` keeps the ranking logic, evidence rule and approval gate; all 8 host paths
  gone. New step 3 detects the agent and asks when signals disagree. The Routing table now
  lists destination *classes*; `AGENT-STRATEGIES.md` resolves each to a location.
- Step 7 gained a branch: a class the agent cannot write is printed as paste-ready text and
  written nowhere, with an explicit ban on substituting a narrower destination.
- `AGENT-STRATEGIES.md` carries the detection table, both agent tables (same 8 classes each,
  including "not writable" rows), and the reason downgrading a global rule to a project rule
  is wrong rather than merely lossy.

### [x] Re-import before Phase 7 (added to scope)
Files: `skills/` (all 16 replaced), `skills/self-improve/AGENT-STRATEGIES.md` (carried forward)
Reason: the Phase 2 import was a snapshot, and `dot-files` landed four commits afterwards
(`6e6ee22`, `2d6d33b`, `32e32b4`, `e854bce`, plus `5734a6c`). The copies had drifted badly —
`github-pr-create` was missing `STACKS.md`, `MECHANICS.md`, `TEMPLATES.md` and all 44
mentions of stacking, and five more skills were missing their split-out bundles.
Gate: re-ran the Phase 4/5/6 edits on the fresh copies, then reversed the two mechanical
renames in a scratch copy and diffed against `dot-files` — every remaining difference is an
intended neutralization and nothing else. `validate.sh` → `ok (16 skills)`.
Set changes: `grill-me` dropped (deleted upstream in `6e6ee22`, superseded by
`grill-with-docs`); `split-stack-pr` added (upstream `5734a6c`, pairs with
`github-pr-create`, which is already here). Count stays 16.
Upstream gains kept: `write-skill`'s 100→150 line rule with its rationale, and every
bundled-file split.

### [x] Phase 7 — rename the scratch convention
Files: 19 files across 10 skills
Gate: `grep -rn '\.claude/scratch' skills/ | wc -l` → `0`;
`grep -rn '\.agents/scratch' skills/ | wc -l` → `48`; all 8 subdirectory names preserved.
`scripts/validate.sh` → `exit=0`, the first full green.
Deviation: 48 occurrences, not the 43 the plan predicted — the extra 5 came with
`split-stack-pr` and the bundled files that landed upstream after the original count.
Also added `gh-stack`, `link`, `submit` to `validate.sh`'s allowlist: `gh-stack` is a real
`gh` extension and the other two are its subcommands, which read as bare skill names once
backticked.

### [x] Phase 8 — bats suite, expected red
Files: `tests/install.bats` (new), `tests/helpers.bash` (new)
Gate: `bats tests/` → 31 of 31 FAIL on exit 127, not on harness errors.
Deviation: the first draft of "`--only` and `--exclude` together is rejected" passed on the
red run, because a missing binary also exits non-zero. Tightened it to assert both flag
names appear in the message, which a 127 cannot satisfy. 31/31 red after that.

### [x] Phase 9 — `install.sh`
Files: `install.sh` (new), `scripts/frontmatter.sh` (new, added to scope)
Gate: `bats tests/` → 32/32 PASS; `shellcheck -x install.sh scripts/*.sh` → no output.
Deviations:
1. Two `rm -rf "$dest/$n"` calls tripped SC2115. Fixed with `"${dest:?}/${n:?}"` rather
   than a suppression — the script does delete directories, so the guard is worth having.
2. **Bug found by smoke-testing `--list`, not by the suite.** Eight skills write their
   description as a YAML folded scalar (`description: >`), and a one-line `sed` returns the
   `>` marker. `validate.sh` had the same reader, so a skill with an empty folded
   description would have passed its non-empty check. Both now share
   `scripts/frontmatter.sh`, so the validator and the installer cannot disagree.
3. The regression test for that bug **passed with the bug reintroduced** on the first
   attempt — its two assertions could not tell `>` from real text. Rewrote it and proved it
   both ways: green with the fix, red with the fix removed. `validate.sh` was likewise
   proved to reject an empty folded description.

### [x] Phase 10 — README and CI
Files: `README.md` (new), `.github/workflows/ci.yml` (new), `CLAUDE.md` (checks section)
Gate: the three CI commands all pass locally.
Deviation: CI and `CLAUDE.md` now run `shellcheck -x`, not plain `shellcheck` — without
`-x` it cannot follow the sourced `scripts/frontmatter.sh` and reports SC1091 instead of
checking the file.

### [x] Phase 11 — remove the 16 from dot-files
Files: `dot-files/claude/.claude/skills/` (16 dirs, 41 files removed), `dot-files/Makefile`
Gate: `ls -1 dot-files/claude/.claude/skills` → exactly `remember` and `work-log`;
`make -n stow-claude` → prints `mkdir -p ~/.claude/skills` above `stow -R claude -t ~`.
**Staged, not committed** — the commit is the user's call.
Note: `split-stack-pr` looked untracked on first inspection but is committed as `5734a6c`
and pushed, so every removal is recoverable through git.

### [x] Phase 12 — unfold stow, install, adopt the new scratch path
Files: `~/.claude/skills/` only, then this plan and deliverable moved to `.agents/scratch/`
Gate: `find ~/.claude/skills -maxdepth 1 -type l | wc -l` → `18`;
`readlink .../remember` → a `dot-files` path; `readlink .../write-plan` → an `agent-skills`
path; `./install.sh --doctor --claude` → 16 `ok`, 0 `BROKEN`, 0 `missing`.
Deviation: the gate said "no `foreign`", but `--doctor` correctly reports `remember` and
`work-log` as `foreign` — they are stow-managed from `dot-files` and this repo does not own
them. That is the ownership rule working, not a failure. The gate's wording was written
before it was clear both trees would share the directory.

## Deviations from the plan

- Phase 1: the plan named `.gitignore` but not its contents. Wrote OS/editor cruft only
  (`.DS_Store`, `*.swp`, `*~`). Deliberately did **not** ignore `.agents/scratch/` — Phase 12
  moves the plan file there, which implies plans and deliverables stay tracked. Flag if that
  is wrong; it is one line to change.
- Phase 1: dropped the `// swap for your display name` comments the design showed in its
  jsonc snippets. JSON has no comments and `jq empty` would have failed on them.
- Phase 3: C-3 said the script "uses `jq` and `python3`". It uses neither. Every frontmatter
  value in all 16 skills is a single-line scalar, so `awk`/`sed` parse them without a YAML
  library, and one less dependency is one less thing CI has to install.
- Phase 3: took three corrections to get a *trustworthy* red, recorded because each was a
  real defect and not tuning:
  1. `set -o pipefail` plus a no-match `grep` returning 1 killed the script mid-run — it
     printed `exit=1` with zero findings, which is indistinguishable from a working gate.
  2. Ten false positives: 5 "broken links" were sample paths inside code fences and inline
     code spans; `gh` and `git` were read as skill names. Fixed by skipping code formatting
     when extracting links, and by an allowlist of frontmatter fields and CLI tool names.
  3. A real miss: the plan predicted `write-skill` would be flagged and it was not. Its
     line 3 reads `(use remember)` unbackticked, and lines 13/63 are backticked with no
     verb, so neither generic pass could see them. `remember` is also an ordinary English
     word — a bare-word search fires on the trigger phrase "what should you remember from
     this". Added an explicit `ABSENT_SKILLS` list matched only in reference shape
     (backticked, or bare after a reference verb), plus a negative control proving the
     English verb stays clean.
- Phase 5's Files list was incomplete in three places; all three were found by
  `validate.sh` rather than by reading, which is the argument for building it first:
  1. `skills/research-solutions/TEMPLATES.md:36` — `~/.claude/CLAUDE.md`, flagged during
     Phase 3 and added to scope with approval before Phase 5 ran.
  2. `skills/write-skill/SKILL.md:27` — `~/.claude/skills/<name>/SKILL.md`, a skill naming
     its own install path, which is exactly the rule in 6.5 of the design.
  3. `skills/write-skill/SKILL.md:88` — `grep -rn '<name>' ~/.claude` in a constraint about
     finding references to a skill.
  So `write-skill` had 4 edit sites, not the 1 the plan implied.
- Phase 6: `EXAMPLES.md` is not exempt from the host-path check, and its worth as a worked
  example comes from naming a home "down to the file". Rather than widen the exemption —
  AC-9 names exactly one exempt file — the example now keeps the concrete *filename*
  (`CLAUDE.md`, `db-migrations.md`) and lets the *directory* be agent-resolved, plus a
  header saying the run detected Claude Code and which items Cursor would hand back
  manually. Specific enough to calibrate against, and AC-9 stays intact.

## Not done / follow-ups

- **Nothing is committed anywhere.** `agent-skills` still has zero commits and no `origin`
  remote; `dot-files` has 41 staged deletions plus a `Makefile` edit. Both commits are the
  user's call.
- **AC-1 and AC-8's first CI run need a remote.** Neither can be proved until the repo is
  pushed to `github.com/siraphobk/agent-skills`.
- **AC-10's Cursor branch is untestable here** — Cursor is not installed on this machine,
  so only the Claude Code half of `AGENT-STRATEGIES.md` has been exercised.
- **`.agents/scratch/` is tracked, not ignored** — carried forward from the Phase 1 call.
  One line in `.gitignore` changes it if that is wrong.
- **Two skills point at "the brain index"**, a `dot-files` concept a teammate cannot follow
  (`research-solutions/SKILL.md`, `research-solutions/TEMPLATES.md`). `validate.sh` cannot
  catch it — it is prose, not a skill reference or a path. Same class as the Fix 1
  dangling pointers, but out of the approved scope, so it was left alone.
- Open question (non-blocking): manifest `owner.name` / `author.name` are both `siraphobk`.
  Swap for a display name if wanted.

## Verification output

```
scripts/validate.sh                     -> validate: ok (16 skills)          exit=0
scripts/validate.sh <bad-name-fixture>  -> FAIL name 'wrong-name' ...        exit=1
bats tests/                             -> 32/32 ok
shellcheck -x install.sh scripts/*.sh   -> no output
./install.sh --cursor --dry-run         -> 16 skills planned
grep host paths outside the exempt file -> no matches
find ~/.claude/skills -type l | wc -l   -> 18
rm -rf ~/.claude/skills; make stow-claude -> unfolded  (then 16 reinstalled -> 18)
./install.sh --doctor --claude          -> 16 ok, 2 foreign (dot-files, correct), 0 BROKEN
```
