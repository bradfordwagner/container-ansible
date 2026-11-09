pkg_installer=${1}
working_dir=${2}

echo pkg_installer=${pkg_installer}

set -ex

alpine_deps() {
  # musl-dev: https://github.com/ocaml/opam-repository/issues/13718
    # py3-pip
  apk add  --no-interactive --no-cache \
    bash \
    gcc \
    libffi-dev \
    musl-dev \
    rsync \
    git
}

arch_deps() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm \
    base-devel \
    wget \
    rsync \
    git
}

debian_deps() {
  apt-get update
  apt-get install -y \
    build-essential \
    wget \
    rsync \
    git
  # Ship no package index: a baked one names exact .deb versions that Debian
  # prunes from the pool on the next point release, so downstream installs 404
  # until this image is rebuilt. Consumers apt-get update against a live mirror.
  rm -rf /var/lib/apt/lists/*
}

${pkg_installer}_deps

# https://docs.astral.sh/uv/reference/environment/
export UV_PYTHON_INSTALL_DIR=/opt/python
export UV_PYTHON_PREFERENCE=only-managed
export UV_PROJECT_ENVIRONMENT=/ansible_env
export UV_NO_CACHE=1

uv_version=0.13.6
uv_dir=$(mktemp -d)
wget -qO- https://github.com/astral-sh/uv/releases/download/${uv_version}/uv-$(uname -m)-unknown-linux-musl.tar.gz | tar -xz -C ${uv_dir} --strip-components=1

# python version: .python-version, ansible + ansible core: pyproject.toml + uv.lock
cd ${working_dir}
${uv_dir}/uv sync --frozen
rm -rf ${uv_dir}
. /ansible_env/bin/activate
python3 --version

# smoketest
bash -lc "/ansible_env/bin/ansible localhost -m ping -c local"
bash -lc "which git"

# run playbook
cd ${working_dir}
ansible-galaxy install -r requirements.yml
ansible-playbook playbook.yml
rm -rf ${working_dir}
