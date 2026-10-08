# test-fastapi-helm

Helm chart for [test-fastapi](https://github.com/MosbahiNihed/test-fastapi), deployed by Argo CD
(Application `test-fastapi-dev`).

PostgreSQL is **not** in this chart: it is deployed separately by
[test-fastapi-postgresql-helm](https://github.com/MosbahiNihed/test-fastapi-postgresql-helm)
(Application `test-fastapi-postgresql-dev`). This chart only connects to it.

## What gets deployed

App `Deployment` + `Service`. Each pod runs, in order:

| Order | Container                         | Notes                                              |
|-------|-----------------------------------|----------------------------------------------------|
| 1     | initContainer `wait-for-db`       | `pg_isready` until PostgreSQL answers              |
| 2     | initContainer `liquibase`         | `liquibase update` (skipped if `liquibase.enabled: false`) |
| 3     | container `api`                   | Readiness probe `/readyz` checks the DB            |

With several replicas every pod runs `update`; Liquibase's lock table makes that safe.

Tekton builds both images (app + Liquibase) from the same commit and writes that commit as
`image.tag` in `values-dev.yaml`. If `liquibase.repository` has no tag, `image.tag` is appended;
if it has one (e.g. `...:latest`) it is used as is.

## Prerequisites

- PostgreSQL release `test-fastapi-postgresql` in the same namespace.
- Secret `test-fastapi-db` (keys `DB_USER`, `DB_PASSWORD`), shared with the PostgreSQL chart:

```bash
kubectl create secret generic test-fastapi-db -n test-fastapi-dev \
  --from-literal=DB_USER=app --from-literal=DB_PASSWORD=$(openssl rand -hex 16)
```

## Configuration = env vars

The app container gets these env vars:

- every item of `env`: `- name: / value:` for plain values, `- name: / valueFrom: secretKeyRef:`
  for secrets (`DB_USER`, `DB_PASSWORD` from the Secret `test-fastapi-db`)
- `env` is a list: `values-<env>.yaml` **replaces** the
  whole list from `values.yaml`, so repeat every variable there

Liquibase is configured separately by the `liquibase` block (`DB_HOST`, `DB_PORT`, `DB_NAME`,
`DB_USER`, `passwordSecret`, `contexts`). It is a map, so `values-<env>.yaml` only sets what changes.

## Key values

| Value                           | Default                                      |
|---------------------------------|----------------------------------------------|
| `env` → `DB_HOST` (required)    | `test-fastapi-postgresql`                    |
| `env` → `DB_PORT` / `DB_NAME`   | `5432` / `app`                               |
| `env` → `DB_USER` / `DB_PASSWORD` | Secret `test-fastapi-db`, keys `DB_USER` / `DB_PASSWORD` |
| `liquibase.repository`          | `kind-registry:5000/test-fastapi-liquibase`  |
| `liquibase.DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` | `test-fastapi-postgresql` / `5432` / `app` / `app` |
| `liquibase.passwordSecret`      | `test-fastapi-db` / `DB_PASSWORD`            |
| `liquibase.contexts`            | `default`; `dev` in `values-dev.yaml` (adds seed users) |
