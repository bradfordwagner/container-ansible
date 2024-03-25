os=${1}

echo os=${os}

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
    python3-dev
}

arch_deps() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm \
    base-devel \
    python \
    wget
}

debian_deps() {
  apt-get update
  apt-get install -y \
    build-essential \
    python3 \
    python3-dev \
    python3-venv \
    wget
}

${os}_deps

cd
python3 -m venv myenv
. myenv/bin/activate

# install pip: https://pip.pypa.io/en/stable/installation/
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

# ansible + ansible core versions
# https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-community-changelogs
ansible_version=9.3.0
python3 -m pip install ansible==${ansible_version}

# smoketest
ansible localhost -m ping -c local
