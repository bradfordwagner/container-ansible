function alpine() {
  echo hello alpine
  apk add git \
          ansible
}

function ubuntu() {
  echo hello ubuntu
  apt update
  apt install software-properties-common -y
  add-apt-repository -y --update ppa:ansible/ansible
  apt install ansible -y
}

