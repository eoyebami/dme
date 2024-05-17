#!/bin/bash
set -x

# launch cluster nodes
fileStatus=$(vagrant validate)
if [[ "${fileStatus}" == *"success"* ]]
then 
  vagrant up
else
  echo "Vagrantfile failed to validate"
  exit 1
fi

# retrieve add worker kubeadm command
addWorkerCmd=$(vagrant ssh controlplane01 -c "kubeadm token create --print-join-command")

# add worker nodes to kubeadm cluster
workerNodes=$(vagrant status | grep node | awk '{print$1}' | tr -d "\n")
for node in ${workerNodes}
do
  vagrant ssh ${node} -c "sudo ${addWorkerCmd}"
  vagrant ssh ${node} -c "echo 'serverTLSBootstrap: true' | sudo tee -a /var/lib/kubelet/config.yaml"
  vagrant ssh ${node} -c "sudo systemctl restart kubelet"
done

# install cluster add-ons
vagrant ssh controlplane01 -c 'bash install-cluster-addons.sh'
