---
name: github-issue-write
model: sonnet
allowed-tools: Bash(gh *) Bash(git remote *) Bash(git rev-parse *) Bash(ls *) Bash(grep *) Bash(mkdir *) Read Write
description: >
  Interactive workflow to draft and create a GitHub Issue in the current project using gh. Detects
  issue templates in .github/ISSUE_TEMPLATE/, asks which template to use (or picks one from
  conversation context when obvious), drafts the issue body to
  .agents/scratch/draft-issues/<filename>.md for user verification, then creates the issue after
  approval. Trigger when user says "create an issue", "open an issue", "file an issue", "write an
  issue", "submit an issue", "draft an issue", "make a GitHub issue", "create a bug report", "file a
  feature request", "open an issue for <repo>", or any intent to create a GitHub issue in the
  current project — whether invoked directly with /github-issue-write or phrased naturally.
---

# GitHub Issue Create Workflow

Use **`gh`** to create the issue. Use `git` locally only to resolve the repo and to
read template files. Require `gh` to be authenticated and `git` to be present.

## Step 0 — Resolve repo and identity

Run the resolution commands in [MECHANICS.md](MECHANICS.md) to get `{owner}`, `{repo}`, and —
if self-assignment comes up later — your login as `{me}`. Those three names are used by every
`gh` call below.

Not in a repo → tell the user to `cd` into the project. `gh` not authenticated → `gh auth login`.

## Step 1 — Detect issue templates

Look in the current project for templates:

```bash
# IMPORTANT: include all three extensions — .yaml is common and easy to miss
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
ls .github/ISSUE_TEMPLATE.md .github/issue_template.md 2>/dev/null
```

If `.github/ISSUE_TEMPLATE/` exists, listing the directory (rather than globbing specific extensions) is the safest way to catch `.md`, `.yml`, AND `.yaml` templates. Do NOT use a glob like `*.md *.yml` — it silently skips `.yaml`, which is the form-template extension many repos use.

Three cases:

- **No templates** → use default body structure (Step 3).
- **Single template** → use it directly. Tell user which template was picked.
- **Multiple templates** → list them by filename + frontmatter `name:` field. Read each template (with the Read tool) so you understand its schema before presenting choices. Ask user which one, OR pick from conversation context if obvious (e.g. user said "bug" + `bug_report.yaml` exists). If 2+ templates plausibly apply (e.g. chore vs refactor vs optimization for a cleanup task), ALWAYS ask — do not silently default.

For `.yml` / `.yaml` form templates: read the schema (`title:` prefix, `labels:`, `body[].attributes.label`, required checkbox blocks) to understand required fields. The body draft must include each labeled section. Note: `gh issue create` takes a single markdown `body` string — form-template structure (including any required `checkboxes` blocks like "Before submission") is NOT auto-rendered, so reproduce those sections as markdown (with checkboxes) in the body yourself.

## Step 2 — Gather issue content

Pull from conversation context first. If gaps, ask user:

- **Title**: concise, imperative. Format: `{verb} {object}` — e.g. "Fix login redirect loop on Safari".
- **Description**: what is the bug / feature / task. Why it matters.
- **Steps to reproduce** (bugs only): numbered list.
- **Expected vs actual** (bugs only).
- **Acceptance criteria** (features only): bullet list.
- **Labels**: derive from template frontmatter `labels:` if set; else ask user.
- **Assignee**: ask if user wants to self-assign (`{me}`) or leave unassigned.
- **Issue type**: assign automatically when the repo's org has issue types configured.
  List the valid types with:

  ```bash
  gh api orgs/{owner}/issue-types --jq '.[].name'
  ```

  This returns 404 for a personal/user account (no org) — then skip type entirely and rely
  on labels alone. When types exist, map the issue's intent to the closest available type by
  name (case-insensitive, allow common synonyms):

  | Intent                              | Pick a type named like        |
  |-------------------------------------|-------------------------------|
  | bug / defect / regression           | `Bug`                         |
  | feature / enhancement / request     | `Feature` or `Enhancement` (`enh`) |
  | chore / refactor / task / docs      | `Task`                        |

  The listed type names are the source of truth — match against them, never invent one. If a
  template was chosen, let it drive the intent (e.g. `bug_report.yaml` → bug). If nothing
  matches with confidence, omit the type rather than guess.

## Step 3 — Build issue body

Shapes are in [TEMPLATES.md](TEMPLATES.md). Which one depends on Step 1:

- **Repo has a template** → fill every section of *theirs*. Do not skip one — use "N/A" if truly
  not applicable. Keep template comments (`<!-- ... -->`) only where they help a reader.
- **No template** → the default body skeleton in TEMPLATES.md, trimmed to the issue kind (a bug
  fills reproduce/expected/actual; a feature fills acceptance criteria).

## Step 4 — Write draft file

Filename: lowercase title, words joined by underscores, max ~6 words, `.md` extension.
Example: "Fix login redirect loop on Safari" → `fix_login_redirect_loop_safari.md`

Write the draft to `.agents/scratch/draft-issues/{filename}` in the project root, using the
draft-file shape in [TEMPLATES.md](TEMPLATES.md). Create the directory if missing (`mkdir -p`).
Add `.agents/scratch/` to `.gitignore` if not present (check with
`grep -q "\.agents/scratch" .gitignore`).

Then show the user the confirm block from TEMPLATES.md and wait for their word.

## Step 5 — Validate labels (only after user confirms)

Before creating, validate each label exists on the repo:

```bash
gh api repos/{owner}/{repo}/labels/{label_name}
```

Returns 404 if the label doesn't exist. If any label is missing, tell the user which one
and ask them to pick an existing label or drop it. Do not invent labels.

## Step 6 — Create issue

Re-read the draft file before creating in case the user edited it. Use the body content
after the `---` metadata separator.

```bash
gh issue create \
  --title "{title}" \
  --body "{issue body}" \
  --label "{label}"      \  # omit flag if no labels
  --type "{issue type}"  \  # omit flag if no type matched in Step 2
  --assignee "@me"          # omit flag if unassigned
```

`--type` takes the type name exactly as listed by `gh api orgs/{owner}/issue-types`. Older `gh`
builds don't know the flag — [MECHANICS.md](MECHANICS.md) has the fallback.

After success, report the issue number and URL from the command output.

Offer to delete draft: "Delete .agents/scratch/draft-issues/{filename}?"

## Error handling

- `gh` not authenticated → tell user to run `gh auth login`
- Not in git repo → `cd` first
- No `origin` remote / can't parse owner+repo → ask user for `{owner}/{repo}`
- Repo has issues disabled → `gh issue create` will fail; report the error and abort
- Title empty → ask user for title
- Label doesn't exist on repo (404 from `gh api`) → ask user to pick an existing label or drop it
