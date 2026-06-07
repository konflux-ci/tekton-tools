---
name: run-lints-and-tests
description: >-
  Run linters and validation checks for tekton-tools. Use when the user asks
  to run tests, validate changes, check YAML, lint commits, or wants to know
  what CI checks before merging.
---

# Running Lints and Tests

This repo has no unit tests. Validation consists of three locally-reproducible
linters plus integration tests that run only in Konflux CI.

## Local Linters

### yamllint

Matches CI exactly. Requires Python 3 and pipenv.

```bash
pipenv sync --dev
pipenv run yamllint .
```

Configuration: `.yamllint` -- disables `line-length`, `key-ordering`,
`document-start/end`; allows flexible list indentation (`indent-sequences: whatever`).
Ignores `/vendor`.

### gitlint

Validates commit messages against conventional commits format and requires a
`Signed-off-by` trailer.

```bash
pip install gitlint
gitlint --fail-without-commits --commits "origin/main..HEAD"
```

Configuration: `.gitlint`

| Rule | Requirement |
|------|-------------|
| Title format | Conventional commits (`feat:`, `fix:`, `chore:`, etc.) |
| Title length | Max 72 characters |
| Body line length | Max 72 characters |
| Body first line | Must be empty (blank line after title) |
| Signed-off-by | Required in body (`git commit -s`) |

Bot commits are auto-ignored (see the `[ignore-by-author-name]` regex in `.gitlint`
for the full list).

### kube-linter

Validates Kubernetes manifests in `config/` and `tasks/`.

```bash
kube-linter lint config/ tasks/ --config .kube-linter.yaml
```

Install from [stackrox/kube-linter releases](https://github.com/stackrox/kube-linter/releases),
or use `go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest`.

Configuration: `.kube-linter.yaml` -- only customization is excluding the `latest-tag`
check (dev deployment; production images are digest-pinned).

### AGENTS.md line count

GitHub Actions enforces that `AGENTS.md` stays under 300 lines:

```bash
wc -l < AGENTS.md
```

This is checked by `.github/workflows/lint.yaml` on every PR.

## Scope

Only `rpms-signature-scan` (in `tasks/rpms-signature-scan/0.2/`) is actively maintained.
The other two tasks are deprecated and pending removal:
- `tasks/generate-odcs-compose/`
- `tasks/provision-env-with-ephemeral-namespace/`

Do not invest effort linting or testing the deprecated tasks.

## Integration Tests (CI Only)

Integration tests run in Konflux via `.tekton/rpms-signature-scan-tests-pull-request.yaml`.
They cannot be run locally -- they require a Konflux cluster with Pipelines-as-Code.

The pipeline injects the PR's version of `rpms-signature-scan` via the PAC annotation:
```yaml
pipelinesascode.tekton.dev/task: tasks/rpms-signature-scan/0.2/rpms-signature-scan.yaml
```

### Test scenarios

Three scenarios run against pinned test images in `quay.io/vanguard_tests/`:

| Scenario | Image | Expected RPMS_DATA |
|----------|-------|--------------------|
| Signed RPMs | `signed-rpms` @ `sha256:3ec7...` | key `199e2f91fd431d51: 95`, `unsigned: 0` |
| Unsigned RPMs | `unsigned-rpms` @ `sha256:076e...` | key `199e2f91fd431d51: 163`, `unsigned: 68` |
| Image index | `image_index` @ `sha256:da4f...` | Aggregates both digests in `IMAGES_PROCESSED` |

Each scenario verifies:
- `TEST_OUTPUT` contains `"completed successfully"` and `"SUCCESS"`
- `RPMS_DATA` matches expected signature key counts
- `IMAGES_PROCESSED` lists the correct digest(s)

### Other CI pipelines

The `test-container-pull-request` pipeline runs all three linters (yamllint,
gitlint, kube-linter) plus builds the root container and runs `rpms-signature-scan`
against it. This is the main quality gate for PRs.

## Quick Checklist

Before pushing a PR, run locally:

```bash
pipenv sync --dev && pipenv run yamllint .
gitlint --fail-without-commits --commits "origin/main..HEAD"
kube-linter lint config/ tasks/ --config .kube-linter.yaml
[ "$(wc -l < AGENTS.md)" -le 300 ] && echo "OK" || echo "AGENTS.md too long"
```
