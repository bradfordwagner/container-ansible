---
name: ansible-python-match
description: Pick the Python version that matches an Ansible release in container-ansible. Use when bumping `ansible` in pyproject.toml, when a Renovate PR for ansible or Python fails `uv lock`, or when asked which Python an Ansible version supports.
---

# Match Python to Ansible

The image runs one uv-managed CPython on every OS. The pin must sit inside the **control node Python** range of the `ansible-core` that the pinned `ansible` package depends on. Every build runs against `localhost`, so control and target Python are the same interpreter.

Files: `pyproject.toml` (`ansible==`, `requires-python`), `.python-version` (exact CPython), `uv.lock`, and the table in `CLAUDE.md`.

## Steps

1. **Find the ansible-core line.** Read the `ansible-core~=` pin of the target `ansible` release:

   ```sh
   curl -s https://pypi.org/pypi/ansible/<VERSION>/json \
     | python3 -I -c "import json,sys;d=json.load(sys.stdin)['info'];print(d['requires_python']);print([r for r in d['requires_dist'] if 'core' in r])"
   ```

2. **Read the support matrix.** The docs site rate-limits scrapers (HTTP 429), so read the source instead:

   ```sh
   gh api repos/ansible/ansible-documentation/contents/docs/docsite/rst/reference_appendices/release_and_maintenance.rst \
     --jq .content | base64 -d \
     | sed -n '/^``ansible-core`` support matrix/,/2\.19/p' | grep -E '^   \* - |Python 3\.1'
   ```

   Each row prints the ansible-core version, then its Control Node Python range, then its Target Python range. Use the **first** `Python` line under the row for the ansible-core line from step 1 (control node). Also note the row for the next ansible-core line, if the table lists one.

3. **Choose the minor.** Pick a minor that sits inside the current row and, when possible, inside the next row too. Then the next Ansible upgrade needs no Python change. Today that is 3.13: it is inside 2.21 (3.12 - 3.14) and 2.22 (3.13 - 3.15).

   Cross-check against PyPI `requires_python` for `ansible` and `ansible-core`. If PyPI and the matrix disagree, the stricter one wins.

4. **Find the latest patch uv can download.**

   ```sh
   uv python list <MINOR> --only-downloads
   ```

   Pick the newest `cpython-<MINOR>.x` entry.

5. **Update the files.**
   - `pyproject.toml`: set `ansible==<VERSION>`, and set `requires-python` to the control node range of the current row, for example `>=3.12,<3.15`.
   - `.python-version`: the exact patch, for example `3.13.18`.
   - Run `uv lock` and commit `uv.lock`.
   - `CLAUDE.md`: update the Ansible / ansible-core / control node Python / EOL table.

6. **Verify** with a real build on at least one Debian-family and one Alpine target:

   ```sh
   docker build --build-arg OS=ghcr.io/bradfordwagner/base:<TAG>-<os> --build-arg pkg_installer=<installer> -t ansible-check .
   docker run --rm ansible-check sh -c 'python3 --version; ansible --version | head -1; ansible localhost -c local -m ping'
   ```

   `python3 --version` must print the `.python-version` value, and the ansible-core version must match step 1.

## Failure modes

- `uv lock` reports no solution for a new `ansible` major: the new core needs a newer Python than `requires-python` allows. Raise the lower bound to the new row, and bump `.python-version` if it falls outside.
- Renovate proposes a Python outside the matrix, such as 3.14 when the pin is 3.13: reject it, or add a `packageRules` cap.
- Do not hardcode a Python version from memory. Always read the matrix, because rows change with each ansible-core release.
