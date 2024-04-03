pkg_installer=${1}

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
    python3 \
    python3-dev \
    git
}

arch_deps() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm \
    base-devel \
    python \
    wget \
    git
}

debian_deps() {
  apt-get update
  apt-get install -y \
    build-essential \
    python3 \
    python3-dev \
    python3-venv \
    wget \
    git
}

${pkg_installer}_deps

cd /
python3 -m venv ansible_env
. ansible_env/bin/activate

# install pip: https://pip.pypa.io/en/stable/installation/
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

# ansible + ansible core versions
# https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-community-changelogs
ansible_version=9.3.0
python3 -m pip install ansible==${ansible_version}

# smoketest
bash -lc "/ansible_env/bin/ansible localhost -m ping -c local"
bash -lc "which git"
