#!/bin/bash
#
#-------------------------------------------# KubeAdm Dependencies

# Build Variables
export PRIMARY_IP=$(hostname -I | awk '{print$2}' | tr -d '\n')
export POD_CIDR="10.244.0.0/16"
export USERS=(vagrant root)
export ISTIO_VERSION="1.21.2"

# initalize cluster
sudo kubeadm init --pod-network-cidr "$POD_CIDR" --apiserver-advertise-address "$PRIMARY_IP"

# create config file
for USER in "${USERS[@]}"
do
  mkdir -p /home/$USER/.kube
  sudo cp -i /etc/kubernetes/admin.conf /home/$USER/.kube/config
  sudo chown -R $(id -u $USER):$(id -g $USER) /home/$USER/.kube
  echo "alias k='kubectl'" | sudo tee -a /home/$USER/.bashrc
done

echo "**********Initalizing Weave**********"
sudo kubectl apply -f "https://reweave.azurewebsites.net/k8s/v1.25/net.yaml?env.IPALLOC_RANGE=${POD_CIDR}" --kubeconfig /home/vagrant/.kube/config

# Install Helm
echo "**********Initalizing Helm**********"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y

# Install Istioctl
echo "**********Initalizing Istioctl**********"
cd /opt
sudo curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" sh -
sudo ln -s /opt/istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/
