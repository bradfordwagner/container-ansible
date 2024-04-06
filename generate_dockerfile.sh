# this is used to generate a docker file in the build task
# input 0 is expected to be the nth upstream item
v=$1
pkg_installer=$(echo ${v} | jq -r '.pkg_installer')
cat <<FOF
RUN ./install_ansible.sh ${pkg_installer}
COPY . /src
ENV PATH="/ansible_env/bin:\${PATH}"
FOF
