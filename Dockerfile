ARG OS

FROM ${OS}
ARG pkg_installer
COPY . /src
WORKDIR /src
RUN ./install_ansible.sh ${pkg_installer} /src
ENV PATH=/ansible_env/bin:${PATH}
