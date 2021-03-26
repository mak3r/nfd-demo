#!/bin/sh

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san susepi --tls-san susepi.local" sh -
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
kubectl create namespace cattle-system
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml
kubectl create namespace cert-manager
curl -L -O https://get.helm.sh/helm-v3.5.3-linux-arm64.tar.gz
tar -xzvf helm-v3.5.3-linux-arm64.tar.gz 
cd linux-arm64/
mv helm /usr/local/bin/
helm repo add jetstack https://charts.jetstack.io
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
helm install   cert-manager jetstack/cert-manager   --namespace cert-manager   --version v1.0.4
kubectl rollout status jetstack/cert-manager -n cert-manager
helm install rancher rancher-stable/rancher   --namespace cattle-system   --set hostname=susepi.lan
kubectl -n cattle-system rollout status deploy/rancher
