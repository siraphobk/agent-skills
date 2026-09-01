# gh / git mechanics

This file holds the command blocks that [SKILL.md](SKILL.md) runs. Nothing here decides anything.
The decisions stay in the workflow steps.

## Resolve repo and identity  (Step 0)

Run these in parallel:

```bash
git rev-parse --is-inside-work-tree
git remote get-url origin   # parse {owner}/{repo} from the URL
```

Parse `{owner}` and `{repo}` from the remote URL. Both of these forms occur:

- `git@github.com:{owner}/{repo}.git`
- `https://github.com/{owner}/{repo}.git`

If the user wants self-assignment later, get your login and call it `{me}`:

```bash
gh api user --jq '.login'
```

## Set the issue type when `--type` is unsupported  (Step 6)

`gh issue create --type` takes the type name exactly as `gh api orgs/{owner}/issue-types` lists
it. An example is `--type "Bug"`. Older `gh` builds fail with the error "unknown flag". Remove the
flag from the create call, and PATCH the type after the issue exists:

```bash
gh api repos/{owner}/{repo}/issues/{number} \
  -X PATCH \
  --field 'type[name]={issue type}'
```
