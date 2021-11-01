alpine() {
  apk add git \
          ansible
}

ubuntu() {
  apt update
  apt install software-properties-common -y
  add-apt-repository -y --update ppa:ansible/ansible
  apt install ansible -y
}

