# bradfordwagner/container-ansible

Builds multi-arch Ansible container images on top of `ghcr.io/bradfordwagner/base` using Dagger.

## Key files

| File | Purpose |
|---|---|
| `config.yaml` | OS targets, archs, upstream base tag |
| `install_ansible.sh` | Installs OS build deps, then `uv sync --frozen` into a venv at `/ansible_env` |
| `pyproject.toml` | `ansible` pin and `requires-python` range |
| `uv.lock` | Locked `ansible` + `ansible-core` + transitive deps |
| `.python-version` | Exact CPython uv downloads into `/opt/python` |
| `.github/renovate/compat.json` | Source of truth: ansible major to ansible-core and control node Python range |
| `.github/renovate/ansible-python.mjs` | Renovate `postUpgradeTasks` script: syncs `requires-python`, `uv.lock`, `.python-version` and the python cap in `renovate.json` to the ansible major |
| `Dockerfile` | Thin wrapper — copies src, runs install script, sets PATH |
| `playbook.yml` | Smoke-tests binaries and runs `andrewrothstein.ca_certs` role |
| `requirements.yml` | Ansible Galaxy deps (`andrewrothstein.ca_certs`) |

## Python

uv downloads one standalone CPython (`.python-version`) on every OS, so the distro Python is never used and is not installed. The pin must sit inside the **control node** Python range of the `ansible-core` that the pinned `ansible` package depends on, per the [ansible-core support matrix](https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-core-support-matrix). Every build runs against `localhost`, so control and target Python are the same interpreter.

`.github/renovate/compat.json` carries this table in machine-readable form. Keep the two in step.

| ansible | ansible-core | Control node Python | ansible-core EOL |
|---|---|---|---|
| 14 | 2.21 | 3.12 - 3.14 | Nov 2027 |
| 15 | 2.22 | 3.13 - 3.15 | May 2028 |

Pin 3.14: it is inside both rows, so the Ansible 14 to 15 upgrade needs no Python change. Keep `requires-python` in `pyproject.toml` equal to the control range of the current row.

## Upgrading Ansible

Renovate runs `ansible-python.mjs` after it bumps `ansible` (see `postUpgradeTasks` in `renovate.json`). The script reads `compat.json` and rewrites `requires-python` in `pyproject.toml` and `uv.lock`, moves `.python-version` to the nearest supported minor when it falls outside the range, and resets the python cap in `renovate.json`. It exits 1 for an ansible major with no `compat.json` row, so the PR goes red.

For a new major, add its row to `compat.json` and the table above **before** merging the Renovate PR. Never push to the `renovate/*` branch: close the PR and make the change on a normal branch. Renovate does not touch `requires-python`.

By hand, if the script did not run:

1. Look up the new `ansible-core` and its control node Python range in the matrix above
2. Update `ansible==` in `pyproject.toml`, widen or narrow `requires-python` to that range
3. Update `.python-version` if the pinned Python falls outside the range
4. Run `uv lock` and commit `uv.lock`
5. Update the table above and `compat.json`

## CI

- **Branch pushes** → `container-branches.yml` builds with `version=latest`
- **Tag pushes** → `container-tags.yml` builds and pushes versioned + manifest
- Uses `dagger-container-builds@0.1.1` module via Dagger 0.15.2
- Watch runs: `gh run list --branch <branch> --limit 5`
