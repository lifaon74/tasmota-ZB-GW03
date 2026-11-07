## Language

- Work, think, and produce only English content: PRs, commits, files, code, docs, issues.
- Converse with the user in the user's language.

## Git workflow

- `main` is protected by the `main-protection` repository ruleset on GitHub: direct pushes, force pushes, and branch deletion are blocked. Every change must land through a Pull Request (no approving review required — a maintainer can merge their own PR).
- Commit on a feature branch, push it, then open the PR (e.g. `git switch -c <branch> && git push -u origin <branch> && gh pr create`). Never commit directly on `main`.

## Agent skills

### Issue tracker

GitHub Issues, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: one `GLOSSARY.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
