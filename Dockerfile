ARG OS

FROM ${OS}
ARG pkg_installer
ARG UV_PYTHON_PREFERENCE=only-system
ARG UV_PYTHON
COPY . /src
WORKDIR /src
RUN ./install_ansible.sh ${pkg_installer} /src
ENV PATH=/ansible_env/bin:${PATH}
