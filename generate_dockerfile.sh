# this is used to generate a docker file in the build task
# input 0 is expected to be the nth upstream item
v=$1
os=$(echo ${v} | jq -r '.os')
cat <<FOF
RUN . ./install_ansible.sh ${os}
FOF
