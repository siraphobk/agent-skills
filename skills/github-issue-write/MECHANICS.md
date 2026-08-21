# gh / git mechanics

The command blocks [SKILL.md](SKILL.md) runs. Nothing here decides anything — the decisions stay
in the workflow steps.

## Resolve repo and identity  (Step 0)

Run these in parallel:

```bash
git rev-parse --is-inside-work-tree
git remote get-url origin   # parse {owner}/{repo} from the URL
```

Parse `{owner}` and `{repo}` from the remote URL. Both forms show up:

- `git@github.com:{owner}/{repo}.git`
- `https://github.com/{owner}/{repo}.git`

If self-assignment is wanted later, get your login and call it `{me}`:

```bash
gh api user --jq '.login'
```

## Setting the issue type when `--type` is unsupported  (Step 6)

`gh issue create --type` takes the type name exactly as listed by
`gh api orgs/{owner}/issue-types` (e.g. `--type "Bug"`). Older `gh` builds error with
"unknown flag" — drop it from the create call and PATCH the type afterward:

```bash
gh api repos/{owner}/{repo}/issues/{number} \
  -X PATCH \
  --field 'type[name]={issue type}'
```
