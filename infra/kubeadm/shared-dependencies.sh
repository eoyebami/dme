#!/bin/bash
#
#-------------------------------------------# KubeAdm Dependencies

# Build Variables
export PRIMARY_IP=$(hostname -I | awk '{print$2}' | tr -d '\n')
export KADM_VERSION="1.29.4-2.1"
export KUBELET_VERSION="1.29.4-2.1"
export KUBECTL_VERSION="1.29.4-2.1"

# Point to Google's DNS server
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
service systemd-resolved restart

# Set up ssh-keys
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# modules necessay for k8 networking and volume support
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# load modules
sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# verify both modules are running
lsmod | grep br_netfilter
lsmod | grep overlay

# verify sys vars are set to 1
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Installing CRT
echo "**********Installing CRT**********"
sudo apt-get update
sudo apt-get install ca-certificates curl jq -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "CRT Installation complete"

# Getting Repo
echo "**********Pulling ContainerD Package Repo**********"
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install containerd.io package
echo "**********Installing and Configuring Containerd.io**********"
sudo apt-get install containerd.io -y
systemctl status containerd

# cgroupsfs driver is set by default, but if your system uses systemd then switch it
echo '
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
' | sudo tee /etc/containerd/config.toml

sudo cat /etc/containerd/config.toml
sudo systemctl restart containerd

sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install apt-transport-https gpg -y

# download signing key for k8 package repo
echo "**********Pulling K8 Package repo**********"
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings, Ubuntu 22.04 and Debian 12 do not have this dir
if ! [ -f /etc/apt/keyrings ]; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
fi

sudo rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "**********Installing KubeAdm Tools**********"
sudo apt-get update
sudo apt-get install -y kubelet="${KUBELET_VERSION}" kubeadm="${KADM_VERSION}" kubectl="${KUBECTL_VERSION}"
sudo apt-mark hold kubelet kubeadm kubectl

# set primary ip for kubelet
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS='--node-ip ${PRIMARY_IP}'
EOF

# Restart kubelet service
sudo systemctl restart kubelet
