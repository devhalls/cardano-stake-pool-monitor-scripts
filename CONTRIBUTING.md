# Contributing

## Commits (tag-line only)

Same policy as Pendulum Arc / Corten:

```
[ADD] Short imperative summary
[SEC] Harden SSH defaults for monitor panes
```

Allowed tags: `[ADD] [UPD] [FIX] [DEL] [REF] [DOC] [TST] [CFG] [DEP] [SEC] [PRF] [REV]`

Rules:

- Every line is a tag line; one tag per line; ≤72 chars; no trailing period
- No free-form body
- No AI/Cursor co-author trailers
- Install hooks: `./scripts/install-hooks.sh`
- Branches: `feature/<slug>`, `fix/<slug>` from `master`; squash-merge preferred
- PR titles use the same tag-line format

Enforced by [`.githooks/commit-msg`](.githooks/commit-msg). Template: [`.gitmessage`](.gitmessage).

## Workflow

1. Fork / branch from `master`
2. Install hooks once: `./scripts/install-hooks.sh`
3. Keep changes focused; update README / SECURITY.md when behaviour or trust boundaries change
4. Open a PR; title uses tag-line format
