# bradfordwagner/container-ansible

Builds multi-arch Ansible container images on top of `ghcr.io/bradfordwagner/base` using Dagger.

## Key files

| File | Purpose |
|---|---|
| `config.yaml` | OS targets, archs, upstream base tag |
| `install_ansible.sh` | Installs Ansible into a venv at `/ansible_env` |
| `Dockerfile` | Thin wrapper — copies src, runs install script, sets PATH |
| `playbook.yml` | Smoke-tests binaries and runs `andrewrothstein.ca_certs` role |
| `requirements.yml` | Ansible Galaxy deps (`andrewrothstein.ca_certs`) |

## Upgrading Ansible

1. Update `ansible_version` in `install_ansible.sh`
2. Update `python_verson` (for RHEL builds) in `install_ansible.sh`
3. Check OS Python compatibility — Ansible 14+ requires Python >= 3.12

## OS Python compatibility

| OS | Python | Min Ansible |
|---|---|---|
| alpine_3.22 | 3.12 | 14 |
| alpine_3.23 | 3.12 | 14 |
| alpine_3.24 | 3.14 | 14 |
| archlinux_latest | 3.13+ (rolling) | 14 |
| debian_bookworm | 3.11 | 12 only — excluded (Python < 3.12) |
| debian_trixie | 3.13 | 14 |
| debian_trixie-slim | 3.13 | 14 |
| debian_forky | 3.13 | 14 |
| debian_forky-slim | 3.13 | 14 |
| ubuntu_noble | 3.12 | 14 |
| ubuntu_plucky | 3.13 | 14 |
| ubuntu_questing | 3.13 | 14 |

`debian_bookworm` and `debian_bookworm-slim` are intentionally excluded — their system Python (3.11) does not meet Ansible 14's `>=3.12` requirement.

## CI

- **Branch pushes** → `container-branches.yml` builds with `version=latest`
- **Tag pushes** → `container-tags.yml` builds and pushes versioned + manifest
- Uses `dagger-container-builds@0.1.1` module via Dagger 0.15.2
- Watch runs: `gh run list --branch <branch> --limit 5`
