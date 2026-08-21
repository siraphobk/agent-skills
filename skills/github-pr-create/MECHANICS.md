# Branch context — the commands

What [SKILL.md](SKILL.md) Step 1 runs to learn where it is. All read-only; run them in parallel.

## Context commands

```bash
# Current branch name
git branch --show-current

# Owner/repo (parse {owner}/{repo} from the URL)
git remote get-url origin

# Base branch (prefer main, fallback to master)
git remote show origin | grep "HEAD branch" | awk '{print $NF}'

# Commits in this branch not in base
git log {base}..HEAD --oneline

# Full diff summary
git diff {base}..HEAD --stat

# Full diff content (for understanding changes)
git diff {base}..HEAD
```

## Parsing the remote

Parse `{owner}` and `{repo}` from the remote URL. Both forms show up:

- `git@github.com:{owner}/{repo}.git`
- `https://github.com/{owner}/{repo}.git`

## Parsing the issue number

Branch names follow `{issue_type}-{issue_number}/{description}` — e.g. `bug-42/fix_auth_crash`.

```bash
echo {branch} | grep -oP '(?<=-)\d+(?=/)'
```

No match means no linked issue. Skip the PR body's "Closes" section; don't guess a number from
the commit messages.
