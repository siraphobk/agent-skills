---
name: find-smells
allowed-tools: Read Grep Glob Write Edit Bash(git *) Bash(mkdir *) Bash(date *)
argument-hint: "[path | diff | branch] [report | apply]"
description: Find code smells in a file, directory, diff, or branch and map each one to a refactoring technique from the refactoring.guru catalog. Scans for the 22 smells in five groups (bloaters, object-orientation abusers, change preventers, dispensables, couplers). Reports findings graded by severity with file:line anchors, the smell name, the technique, and a short before-and-after sketch. Writes the report to .agents/scratch/reviews/ on request. Applies a refactoring only after the user approves that finding, then runs the pre-done checks. Use when the user says "find code smells", "smell check", "what should I refactor here", "which refactoring fits this", "clean up this file", or "review this for smells". NOT for bugs or correctness review (use code-review or github-pr-review), NOT for a whole PR review (use github-pr-review), and NOT for a pre-change survey of an issue (use analyze-issue).
---

# Find Smells

Read the code, name each smell from the catalog, and name the technique that the
catalog prescribes for it. Change no code until the user approves a finding.

## Arguments

The invocation can carry up to two words, in any order.

| Word | Meaning |
|---|---|
| a path | Scan that file or directory |
| `diff` | Scan the uncommitted changes |
| `branch` | Scan the commits of the current branch against its base |
| `report` | Stop at the report. This is the default. |
| `apply` | Report, then apply each approved finding |

With no target word, ask for one. Do not guess.

## Workflow

1. **Get the target.** Make the file list.
   - For a path, use Glob. For `diff`, run `git diff --name-only` and add
     `git diff --name-only --cached`. For `branch`, run
     `git diff --name-only $(git merge-base HEAD main)..HEAD`. The base is
     `master` when `main` does not exist.
   - Skip generated code, lock files, and vendored files. Say that you skipped
     them.
   - Read each remaining file in full. A smell such as Divergent Change is not
     visible in a diff hunk.

2. **Map the surface.** For a directory or a branch, list the modules, the main
   types, and who calls whom. Two lines per module are enough. Couplers and
   change preventers live between files, so this map is the only way to see
   them.

3. **Scan by group.** Read [CATALOG.md](CATALOG.md). Walk the five groups in
   the order of the catalog. For each smell, check three things:
   - The **signs** line. The code must match it.
   - The **language note**. Some smells do not exist in Go, Rust, or Bash. Some
     smells change shape there. Follow the note.
   - The **ignore** line. When the code matches it, do not report the smell.
     Record it in the *Seen and ignored* table instead.

   Every finding must cite a `path:line`. A smell that you cannot anchor is not
   a finding.

4. **Grade each finding.** Use three levels.
   - 🔴 **Fix now.** The smell blocks a change that the user named. No change
     named means no 🔴.
   - 🟡 **Fix soon.** The smell costs the next reader real time. Most bloaters,
     couplers, and duplicate code land here.
   - 🔵 **Nit.** A small, local smell. Most dispensables land here.

   Do not report style or formatting. Do not report a bug. A bug goes to the
   `diagnose` skill.

5. **Gate on the report.** Fill [TEMPLATE.md](TEMPLATE.md) and show it in chat.
   Then walk the findings one by one. The user accepts or drops each one.
   Nothing leaves the chat before this walk is done.
   - Save the report only when the user asks. Write it to
     `.agents/scratch/reviews/YYYY-MM-DD-smells-<slug>.md`. The slug is the
     target name in kebab case.
   - In `report` mode, stop here.

6. **Apply, one finding at a time.** This step runs in `apply` mode only.
   - Take the accepted findings in severity order.
   - Apply the technique in the small steps that the catalog page describes.
     Run the test suite after each step. Stop at the first failure and show it.
   - Show the diff of each finding before you start the next one.
   - Run the pre-done checks from your agent instructions file when the last
     finding lands.
   - Do not add a feature, fix a bug, or rename for taste while you apply.
     Behaviour must not change.

7. **Hand off.** Say which skill runs next. Do not invoke it.
   - A finding that needs more than about an hour of work is a plan, not an
     edit. Recommend the `write-plan` skill for it.
   - After applied changes, recommend the `github-pr-create` skill.

## Constraints

- **Read the whole file, not the diff hunk.** The diff is only the file list.
- **Never edit before the user accepts that finding.** The walk in step 5 is
  the only approval. A "looks good" on the whole report is not a per-finding
  yes.
- **Never commit or push.** The git rules of your agent own that.
- **Name the smell and the technique exactly as the catalog does.** A reader
  looks them up on the site. The URL is in [CATALOG.md](CATALOG.md).
- **One technique per finding, plus one alternative at most.** The catalog
  lists several. Pick the one that the condition column selects. Say why.
- **Give a sketch, not a rewrite.** Ten lines of before and ten lines of
  after. Enough to see the shape. The full change happens in step 6.
- **Respect the ignore lines.** A `switch` inside a factory is not a smell. A
  comment that says *why* is not a smell. The catalog lists these.
- **Match the density of [EXAMPLES.md](EXAMPLES.md).** It shows one finding
  too coarse and the same finding right.
- **Scratch output goes to `.agents/scratch/reviews/`.** Never `/tmp` and
  never the repo root.
