# Tekton Tools

Tekton tasks and pipeline used by AppStudio.


## Installation

Requires a cluster with the Tekton Task CRD and `kubectl`. Apply the actively
maintained tasks:

```bash
kubectl apply -f tasks/rpms-signature-scan/0.2/rpms-signature-scan.yaml -n <namespace>
kubectl apply -f tasks/build-helm-chart-oci-ta/0.4/build-helm-chart-oci-ta.yaml -n <namespace>
```

## Usage

Task parameters and results are documented in each version directory's `README.md`
(for example [`tasks/rpms-signature-scan/0.2/README.md`](tasks/rpms-signature-scan/0.2/README.md)
and [`tasks/build-helm-chart-oci-ta/0.4/README.md`](tasks/build-helm-chart-oci-ta/0.4/README.md)).
How CI runs tasks against sample images: [AGENTS.md](AGENTS.md) (CI / Testing) and
the `.tekton/*-tests-pull-request.yaml` pipelines.

## Development

See [AGENTS.md](AGENTS.md) for linting, CI, and how to add or update tasks.

```bash
pipenv sync --dev
pipenv run yamllint .
```
