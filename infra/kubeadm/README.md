## KubeAdm Cluster Creation Automation for Vagrant
This repository consists of scripts related to KubeAdm cluster set up on a vagrant env

## Prerequisites
* `Vagrant` must be installed on your system
* System must have at least `16GB` of ram

## Content
* `Vagrantfile`: configuration for spinning up cluster nodes
  - Default is 1 master and 1 worker node
* `shared-dependencies.sh`: script that installs necessary dependencies for both worker and mmaster nodes
* `init-cluster.sh`: initalizes kubeadm and installs necessary dependencies for master node
* `install-cluster-addons.sh`: installs cluster addons such as `istio`, `cert-manager`, `metrics-server`
* `setup-kubeadm.sh`: parent script for spinning up cluster, also configures minor dependencies

## Steps to deploy KubeAdm
- `Deploy Cluster for the first time`: this will spin up the kubeadm cluster
```bash
    ./setup-kubeadm.sh start
```
- `Recreate Cluster`: if you encounter any issues, this will tear down and recreate the cluster
```baah
    ./setup-kubeadm.sh restart
```
- `Destroy Cluster`: this will tear down the cluster
```bash
    ./setup-kubeadm.sh destroy
```

## Help
* If you encounter an issues, primarily in the steps where `vagrant ssh ${node} -c` is being used to run remote commands to vms from the `setup-kubeadm.sh` script:
  - Run a `vagrant ssh ${node}` in a separate terminal, this should unblock vagrant
* If you run into an issue where the worker nodes addition error, or if the master itself fails to initialize:
  - Run a `./setup-kubeadm.sh restart`
