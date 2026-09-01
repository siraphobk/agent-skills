# Branch context commands

[SKILL.md](SKILL.md) Step 1 runs these commands to find the branch context. All of them are
read-only. Run them in parallel.

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

## Parse the remote

Parse `{owner}` and `{repo}` from the remote URL. The URL has one of two forms:

- `git@github.com:{owner}/{repo}.git`
- `https://github.com/{owner}/{repo}.git`

## Parse the issue number

Branch names follow the pattern `{issue_type}-{issue_number}/{description}`. One example is
`bug-42/fix_auth_crash`.

```bash
echo {branch} | grep -oP '(?<=-)\d+(?=/)'
```

No match means the branch has no linked issue. Skip the "Closes" section of the PR body. Do not
guess a number from the commit messages.
