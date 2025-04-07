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
    python3 \
    python3-dev \
    rsync \
    git
}

arch_deps() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm \
    base-devel \
    python \
    wget \
    rsync \
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
    rsync \
    git
}

rhel_deps() {
  cd /tmp
  dnf install -y --allowerasing \
    bzip2-devel \
    curl \
    findutils \
    gcc \
    git \
    libffi-devel \
    make \
    openssl-devel \
    tar \
    wget \
    which \
    xz \
    rsync \
    zlib-devel

  # I removed rocky 8 for this error:
  # 97  : │ [6m9s] | fatal: [localhost]: FAILED! => {"changed": false, "module_stderr": "Traceback (most recent call last):\n  File \"<stdin>\", line 12, in <module>\n  File \"<frozen importlib._bootstrap>\", line 971, in _find_and_load\n  File \"<frozen importlib._bootstrap>\", line 951, in _find_and_load_unlocked\n  File \"<frozen importlib._bootstrap>\", line 894, in _find_spec\n  File \"<frozen importlib._bootstrap_external>\", line 1157, in find_spec\n  File \"<frozen importlib._bootstrap_external>\", line 1131, in _get_spec\n  File \"<frozen importlib._bootstrap_external>\", line 1112, in _legacy_get_spec\n  File \"<frozen importlib._bootstrap>\", line 441, in spec_from_loader\n  File \"<frozen importlib._bootstrap_external>\", line 544, in spec_from_file_location\n  File \"/tmp/ansible_ansible.legacy.dnf_payload_z8v1z445/ansible_ansible.legacy.dnf_payload.zip/ansible/module_utils/basic.py\", line 5\nSyntaxError: future feature annotations is not defined\n", "module_stdout": "", "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", "rc": 1}
# likely because of wrong python version being picked up. need to circle back on this

  # maybe we should be installing python for all os
  # https://www.python.org/doc/versions/
  python_verson=3.12.8
  wget https://www.python.org/ftp/python/${python_verson}/Python-${python_verson}.tar.xz
  xz -d -v Python-${python_verson}.tar.xz
  tar xf Python-${python_verson}.tar
  cd Python-${python_verson}
  ./configure --enable-optimizations
  make -j 2
  nproc
  make altinstall
  ln -s /usr/local/bin/python3.12 /usr/local/bin/python3

  # smoketest python install
  python3.12 --version
  python3 --version

  # cleanup
  rm -rf /tmp/*
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
ansible_version=11.4.0
python3 -m pip install ansible==${ansible_version}

# smoketest
bash -lc "/ansible_env/bin/ansible localhost -m ping -c local"
bash -lc "which git"

# run playbook
cd ${working_dir}
ansible-galaxy install -r requirements.yml
ansible-playbook playbook.yml
rm -rf ${working_dir}
