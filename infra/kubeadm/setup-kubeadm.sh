#!/bin/bash
set -e

# cluster start up
startCluster () {
  # validate Vagrantfile
  fileStatus=$(vagrant validate)
  if [[ "${fileStatus}" == *"success"* ]]
  then
    echo "*********************************"
    echo "Vagrantfile validated successfully"
    echo "Setting Up KubeAdm Cluster..."
    echo "*********************************"
    vagrant up
  else
    echo "Vagrantfile failed to validate"
    exit 1
  fi

  # retrieve add worker kubeadm command
  addWorkerCmd=$(vagrant ssh controlplane01 -c "kubeadm token create --print-join-command")
  while [[ "${addWorkerCmd}" != *"kubeadm join"* ]]
  do
    echo "*********************************"
    echo "Command to add worker node was not generated properly, trying again..."
    echo "*********************************"
    addWorkerCmd=$(vagrant ssh controlplane01 -c "kubeadm token create --print-join-command")
  done

  # add worker nodes to kubeadm cluster
  workerNodes=$(vagrant status | grep node | awk '{print$1}')
  for node in ${workerNodes}
  do
    echo "*********************************"
    echo "Adding ${node} to KubeAdm Cluster"
    echo "*********************************"
    vagrant ssh ${node} -c "sudo ${addWorkerCmd}"
    vagrant ssh ${node} -c "echo 'serverTLSBootstrap: true' | sudo tee -a /var/lib/kubelet/config.yaml"
    vagrant ssh ${node} -c "sudo systemctl restart kubelet"
  done

  # install cluster add-ons
  echo "*********************************"
  echo "Installing Cluster Add-Ons"
  echo "*********************************"
  vagrant ssh controlplane01 -c 'bash install-cluster-addons.sh'

  # Add Hostnames to /etc/hosts 
  echo "*********************************"
  echo "Appending /etc/hosts file with cluster nodes"
  echo "*********************************"
  clusterNodes=$(vagrant status | grep 'node\|controlplane' | awk '{print$1}')
  for node in ${clusterNodes}
  do
    nodeHostname=$(vagrant ssh "${node}" -c 'hostname')
    nodeIp=$(vagrant ssh "${node}" -c 'hostname -I' | awk '{print$2}')
    for clusterNode in ${clusterNodes}
    do
      if [[ "${node}" != "${clusterNode}" ]]
      then
	vagrant ssh "${clusterNode}" -c "echo '${nodeIp} ${nodeHostname}' | sudo tee -a /etc/hosts"
      fi
    done
  done

  # Copy SSH keys
  echo "*********************************"
  echo "Enabling SSH between cluster nodes"
  echo "*********************************"
  for node in ${clusterNodes}
  do
    for clusterNode in ${clusterNodes}
    do
      if [[ "${node}" != "${clusterNode}" ]]
      then
        vagrant ssh "${node}" -c "sshpass -p vagrant ssh-copy-id ${clusterNode} -o StrictHostKeyChecking=no -p 22"
      fi
    done
  done

  # deactivate PasswordAuthentication in Cluster Nodes
  echo "*********************************"
  echo "Deactivating PasswordAuthentication in Cluster Nodes"
  echo "*********************************"
  for node in ${clusterNodes}
  do
    vagrant ssh "${node}" -c "sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    vagrant ssh "${node}" -c "sudo systemctl restart sshd"
    vagrant ssh "${node}" -c "rm -rf *"
  done
}

case "$1" in
    "start")
      startCluster
    ;;
    "restart")
      vagrant destroy --force
      echo "*********************************"
      echo "Virtual Machines have been removed"
      echo "*********************************"
      startCluster 
    ;;
    "destroy")
      vagrant destroy --force 
      echo "*********************************"
      echo "Virtual Machines have been removed"
      echo "*********************************"
    ;;
esac
