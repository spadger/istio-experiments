#!/bin/zsh

set -e

# In separate windows, I ran:
#   $ minikube start
#   $ minikube dashboard
#   $ minikube tunnel


helm repo list | grep -q istio || helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl get ns istio-system &>/dev/null || kubectl create namespace istio-system
helm -n istio-system install istio-base istio/base

helm -n istio-system install istiod istio/istiod --wait

# install istio-ingress
kubectl get ns istio-ingress &>/dev/null || kubectl create namespace istio-ingress
kubectl label namespace istio-ingress istio-injection=enabled
helm install ingress-gw istio/gateway -n istio-ingress --wait

# install kiali and prometheus
helm install --namespace istio-system --set auth.strategy="anonymous" --repo https://kiali.org/helm-charts  kiali-server kiali-server
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.16/samples/addons/prometheus.yaml
kubectl -n istio-system patch svc kiali -p '{"spec": {"type": "LoadBalancer"}}'

# install apps
kubectl get ns apps &>/dev/null || kubectl create ns apps
kubectl label namespace apps istio-injection=enabled
kubectl -n apps apply -f res/a.yaml
kubectl -n apps apply -f res/b.yaml


# bind istio mesh
kubectl -n istio-ingress apply -f res/gateway.yaml
kubectl -n apps apply -f res/virtualservice.yaml





