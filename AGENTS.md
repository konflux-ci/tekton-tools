# Agent Guidelines for tekton-tools

## Project Overview

Tekton tasks and pipelines used by Konflux.
The repo contains
reusable Tekton Task definitions, CI pipeline definitions that build and test
those tasks, and supporting configuration for Kerberos-based compose generation.

## Project Structure

- `tasks/<name>/<version>/` -- Versioned Tekton Task definitions (YAML), each
  with its own `kustomization.yaml`, `README.md`, and optional `MIGRATION.md`
- `tasks/<name>/OWNERS` -- Per-task approver lists (Prow-style OWNERS files)
- `.tekton/` -- Pipelines-as-Code PipelineRun definitions that run on PRs and
  pushes (Konflux CI). These build container images and run task-level tests.
- `config/` -- Kubernetes manifests for supporting infrastructure (e.g. Kerberos
  cache CronJob, ServiceAccount, Role, RoleBinding)
- `repos.d/` -- Yum `.repo` files used during container builds
- `.github/workflows/` -- GitHub Actions workflows (fullsend agent dispatch)

## Active Tasks

- **rpms-signature-scan** (`tasks/rpms-signature-scan/0.2/`): Scans RPMs in a
  container image and reports signature status. Uses `rpm_verifier` from
  `quay.io/konflux-ci/tools`. This is the primary actively maintained task.
- **generate-odcs-compose** (`tasks/generate-odcs-compose/`): **Deprecated**.
  Generates ODCS composes for RPM repositories.
- **provision-env-with-ephemeral-namespace** (`tasks/provision-env-with-ephemeral-namespace/`):
  **Deprecated**. Replaced by `eaas-provision-space`.
- **create-pull-request** (`tasks/create-pull-request.yaml`): Clones a target
  repo, runs a script, and creates a pull request with the changes.

## Task Versioning Convention

Tasks follow `<name>/<major>.<minor>/` directory layout:
- Bump the minor version for backwards-compatible changes
- Bump the major version for breaking changes
- Each version directory contains the task YAML, `kustomization.yaml`, and `README.md`
- Breaking changes require a `MIGRATION.md` with user-facing migration steps
- Patch versions (e.g. `0.2.1`) use migration scripts in `migrations/<version>.sh`
  and update the `app.kubernetes.io/version` label in the task YAML

## CI / Testing

CI runs via Konflux Pipelines-as-Code (`.tekton/` directory). On every PR:
- `rpms-signature-scan-v02-pull-request` -- Builds the task container image
- `rpms-signature-scan-tests-pull-request` -- Runs the task against known signed,
  unsigned, and image-index test images, then verifies `TEST_OUTPUT`, `RPMS_DATA`,
  and `IMAGES_PROCESSED` results
- `test-container-pull-request` -- Builds the repo-level test container

There are no unit tests. Testing is done by running the actual Tekton tasks
against known container images and verifying the task results match expected output.

## Development Constraints

- Container images must be referenced by digest (`@sha256:...`), never by tag
- Task images come from `quay.io/konflux-ci/tools` or `quay.io/konflux-ci/konflux-test`
- Base images use `registry.access.redhat.com/ubi9/ubi-minimal`
- Renovate manages image digest updates (see `renovate.json`)
- Commit messages must follow conventional commits format and include
  `Signed-off-by` (enforced by `.gitlint`)
- YAML files are linted with yamllint (config in `.yamllint`)
- Kubernetes manifests are linted with kube-linter (config in `.kube-linter.yaml`)

## How to Add or Update a Task

1. Create or edit `tasks/<name>/<version>/<name>.yaml` with the Tekton Task spec
2. Add a `kustomization.yaml` referencing the task YAML
3. Add a `README.md` documenting parameters, results, and usage
4. If breaking changes: create `MIGRATION.md` with migration steps
5. Add an `OWNERS` file listing approvers for the task
6. Add a `.tekton/<name>-pull-request.yaml` PipelineRun to test the task on PRs
7. Add a `.tekton/<name>-push.yaml` PipelineRun for post-merge builds

## Kerberos Configuration

The generate-odcs-compose task requires Kerberos authentication. The setup
involves a keytab secret and a CronJob (`config/cache-cronjob.yaml`) that
refreshes the Kerberos cache every 8 hours. See `README.md` for details.
