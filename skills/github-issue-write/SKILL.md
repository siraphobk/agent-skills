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

Use **`gh`** to create the issue. Use `git` only for two local jobs. It finds the repo, and it
reads template files. `gh` must be authenticated. `git` must be installed.

## Step 0: Resolve repo and identity

Run the commands in [MECHANICS.md](MECHANICS.md). They give you `{owner}` and `{repo}`. They also
give your login as `{me}`, which you need only for self-assignment later. Every `gh` call below
uses these three names.

Not in a repo → tell the user to `cd` into the project. `gh` not authenticated → `gh auth login`.

## Step 1: Detect issue templates

Look in the current project for templates:

```bash
# IMPORTANT: include all three extensions — .yaml is common and easy to miss
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
ls .github/ISSUE_TEMPLATE.md .github/issue_template.md 2>/dev/null
```

If `.github/ISSUE_TEMPLATE/` exists, list the whole directory. Do NOT glob for specific extensions. The directory listing catches `.md`, `.yml`, AND `.yaml` templates. A glob like `*.md *.yml` skips `.yaml` without any warning. Many repos use `.yaml` for their form templates.

Three cases:

- **No templates** → use the default body structure (Step 3).
- **Single template** → use it directly. Tell the user which template you picked.
- **Multiple templates** → list them by filename and frontmatter `name:` field. Read each template with the Read tool. You must know the schema of each one before you offer a choice. Ask the user which template to use. You can also pick from conversation context when the choice is obvious. For example, the user says "bug" and `bug_report.yaml` exists. If two or more templates can apply, ALWAYS ask. For example, chore, refactor, and optimization all fit a cleanup task. Never pick a default in silence.

For `.yml` and `.yaml` form templates, read the schema to find the required fields. The schema holds the `title:` prefix, `labels:`, `body[].attributes.label`, and the required checkbox blocks. The body draft must include each labeled section. `gh issue create` takes a single markdown `body` string. It does NOT render the form-template structure for you. This includes any required `checkboxes` block, such as "Before submission". Write those sections yourself as markdown, with the checkboxes.

## Step 2: Gather issue content

Take the content from conversation context first. Ask the user about each gap.

| Field | What to put in it |
|---|---|
| Title | Short and imperative. Format: `{verb} {object}`. Example: "Fix login redirect loop on Safari". |
| Description | The bug, the feature, or the task. Also why it matters. |
| Steps to reproduce | Bugs only. A numbered list. |
| Expected vs actual | Bugs only. |
| Acceptance criteria | Features only. A bullet list. |
| Labels | Take them from the template frontmatter `labels:` field. If it is not set, ask the user. |
| Assignee | Ask the user for self-assignment (`{me}`) or for no assignee. |

### Issue type

Assign a type when the repo's org has issue types configured. List the valid types with:

```bash
gh api orgs/{owner}/issue-types --jq '.[].name'
```

The command returns 404 for a personal account, because it has no org. In that case, skip the
type and use the labels alone. When types exist, match the issue intent to the closest type name.
Ignore case, and allow common synonyms.

| Intent                              | Pick a type named like        |
|-------------------------------------|-------------------------------|
| bug / defect / regression           | `Bug`                         |
| feature / enhancement / request     | `Feature` or `Enhancement` (`enh`) |
| chore / refactor / task / docs      | `Task`                        |

The listed type names are the source of truth. Match against them, and never invent one. If you
chose a template, the template sets the intent. For example, `bug_report.yaml` means a bug. If no
type matches with confidence, omit the type. Do not guess.

## Step 3: Build issue body

[TEMPLATES.md](TEMPLATES.md) holds the shapes. Step 1 decides which shape you use.

- **Repo has a template** → fill every section of *their* template. Do not skip a section. Write
  "N/A" when a section truly does not apply. Keep template comments (`<!-- ... -->`) only where
  they help a reader.
- **No template** → use the default body skeleton in TEMPLATES.md. Cut it down to the issue kind.
  A bug fills reproduce, expected, and actual. A feature fills acceptance criteria.

## Step 4: Write draft file

Filename: lowercase title, words joined by underscores, max ~6 words, `.md` extension.
Example: "Fix login redirect loop on Safari" → `fix_login_redirect_loop_safari.md`

Write the draft to `.agents/scratch/draft-issues/{filename}` in the project root. Use the
draft-file shape in [TEMPLATES.md](TEMPLATES.md). Create the directory with `mkdir -p` if it does
not exist. Add `.agents/scratch/` to `.gitignore` if the line is not there. Check with
`grep -q "\.agents/scratch" .gitignore`.

Then show the user the confirm block from TEMPLATES.md. Wait for their answer.

## Step 5: Validate labels (only after user confirms)

Before you create the issue, check that each label exists on the repo:

```bash
gh api repos/{owner}/{repo}/labels/{label_name}
```

The command returns 404 when the label does not exist. Tell the user which label is missing. Ask
the user to pick a label that exists, or to remove it. Do not invent labels.

## Step 6: Create issue

Read the draft file again before you create the issue, because the user may have edited it. Use
the body content after the `---` metadata separator.

```bash
gh issue create \
  --title "{title}" \
  --body "{issue body}" \
  --label "{label}"      \  # omit flag if no labels
  --type "{issue type}"  \  # omit flag if no type matched in Step 2
  --assignee "@me"          # omit flag if unassigned
```

`--type` takes the type name exactly as `gh api orgs/{owner}/issue-types` lists it. Older `gh`
builds do not know the flag. [MECHANICS.md](MECHANICS.md) has the fallback.

After the command succeeds, report the issue number and URL from the output.

Offer to delete the draft. Ask: "Delete .agents/scratch/draft-issues/{filename}?"

## Error handling

| Problem | What to do |
|---|---|
| `gh` is not authenticated | Tell the user to run `gh auth login`. |
| You are not in a git repo | Tell the user to `cd` into the project first. |
| No `origin` remote, or you cannot parse the owner and repo | Ask the user for `{owner}/{repo}`. |
| The repo has issues disabled | `gh issue create` fails. Report the error and stop. |
| The title is empty | Ask the user for a title. |
| The label does not exist on the repo (404 from `gh api`) | Ask the user to pick a label that exists, or to remove it. |
