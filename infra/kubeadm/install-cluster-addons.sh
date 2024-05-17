#!/bin/bash
#
#-------------------------------------------# KubeAdm Dependencies

# Build Variables
export METRIC_SERVER_VERSION="3.12.1"
export CERT_MANGER_VERSION="1.14.5"

# Install Istio Componentes
sudo istioctl install --set profile=default -y --kubeconfig /home/vagrant/.kube/config

# Install cert-manager
sudo kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/v${CERT_MANGER_VERSION}/cert-manager.yaml" --kubeconfig /home/vagrant/.kube/config

# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
