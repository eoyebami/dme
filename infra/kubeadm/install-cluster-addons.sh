#!/bin/bash
#
#-------------------------------------------# KubeAdm Dependencies

# Build Variables
export METRIC_SERVER_VERSION="3.12.1"
export CERT_MANGER_VERSION="1.14.5"

# Modify kubelet-config
echo "**********Configuring ServerTLSBootstrap for Kubelet**********"
kubectl get cm -nkube-system kubelet-config -o yaml --kubeconfig /home/vagrant/.kube/config | sed '/apiVersion: kubelet.config.k8s.io/a\    serverTLSBootstrap: true' > kubelet-config.yaml
kubectl apply -f kubelet-config.yaml --kubeconfig /home/vagrant/.kube/config
echo "serverTLSBootstrap: true" | sudo tee -a /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet

echo "**********Approving Kubelet Node CSRs**********"
# wait for kubelet-serving csrs to be generated
while [[ `kubectl get csr -nkube-system --kubeconfig /home/vagrant/.kube/config | grep -c kubelet-serving` -lt 2 ]]
do
  echo "Not all nodes in the cluster have generated kubelet-serving csrs, Please wait..."
  sleep 5
done

# for loop to approve all csrs
csrs="$(kubectl get csr -nkube-system --kubeconfig /home/vagrant/.kube/config -o custom-columns=NAME:.metadata.name --no-headers)"
for csr in ${csrs}
do
  kubectl certificate approve ${csr} --kubeconfig /home/vagrant/.kube/config
done

# Install Istio Componentes
sudo istioctl install --set profile=default -y --kubeconfig /home/vagrant/.kube/config

# Install cert-manager
sudo kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/v${CERT_MANGER_VERSION}/cert-manager.yaml" --kubeconfig /home/vagrant/.kube/config

# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
