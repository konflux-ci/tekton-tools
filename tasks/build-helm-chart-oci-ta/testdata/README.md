# build-helm-chart-oci-ta test fixtures

Charts used by `.tekton/build-helm-chart-oci-ta-tests-pull-request.yaml`.

| Fixture | Exercises |
|---------|-----------|
| `chart/` | Default overwrite path (`OVERWRITE_CHART_NAME=true`, `SOURCE_CODE_DIR=app`): Chart.yaml `name: test-chart` is rewritten to match the IMAGE repo basename before push. `IMAGE_MAPPINGS` substitutes `localhost/test-chart:old` in `values.yaml` and templates. |
| `product-chart/` | `OVERWRITE_CHART_NAME=false`: Chart.yaml name is kept (not rewritten). Chart `name` matches the onboarded Quay repo (`build-helm-chart-oci-ta-v04`) so CI can push without a separate ImageRepository. |
| `chart-http-deps/` | `Chart.lock` rebuild from an HTTPS chart repository (`https://charts.jetstack.io`, trust-manager). The `charts/` directory is not committed; CI must register the HTTP repo and run `helm dependency build` before package. Requires cluster egress to jetstack. |

The `templates/deployment.yaml` files are minimal Helm chart content so `helm
package` produces a valid chart; they are not deployed in CI.

## No-overwrite regression coverage

The two CI branches use different semver tags (`0.1.0_test` vs `0.2.0_preserve`)
and different `IMAGE` tags (`helm-e2e-on-pr-*` vs `helm-no-overwrite-on-pr-*`).
Verification checks both via `skopeo` on the semver ref and the additional tag.
That proves each branch pushed and tagged its own artifact.

That does **not** prove `OVERWRITE_CHART_NAME=false` was honored: when Chart.yaml
`name` matches the IMAGE repo basename (`build-helm-chart-oci-ta-v04`), a broken
implementation that still overwrites the name produces the same chart path and
tags.

To catch that naming regression in CI, `IMAGE_URL` would need to contain the
preserved chart name (for example `test-chart:0.2.0_preserve`), which requires
push access to that Quay repository. Otherwise rely on
[konflux-ci/tools](https://github.com/konflux-ci/tools) unit tests
(`internal/helmchartoci/`).
