set -e


# add repo
helm repo list | grep -q istio || helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# install base
kubectl get ns istio-system &>/dev/null || kubectl create namespace istio-system
helm -n istio-system upgrade --install istio-base istio/base

# install istiod
helm -n istio-system upgrade --install istiod istio/istiod --wait

# install istio-ingress
kubectl get ns istio-ingress &>/dev/null || kubectl create namespace istio-ingress
kubectl label namespace istio-ingress istio-injection=enabled
helm  -n istio-ingress upgrade --install ingress-gw istio/gateway --wait
kubectl -n istio-ingress get svc ingress-gw

# install kiali and path service
helm -n istio-system upgrade --install --set auth.strategy="anonymous" --repo https://kiali.org/helm-charts  kiali-server kiali-server --wait 
kubectl -n istio-system patch svc kiali -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n istio-system get svc kiali


# install apps
kubectl get ns apps &>/dev/null || kubectl create ns apps
kubectl label namespace apps istio-injection=enabled

kubectl -n apps apply -f res/a.yaml
kubectl -n apps apply -f res/b.yaml
kubectl -n apps get svc 

# install gateway
kubectl -n istio-ingress apply -f res/gateway.yaml

# install VirtualService
kubectl -n apps apply -f res/virtualservice.yaml

kubectl -n istio-ingress get svc ingress-gw
ip=$(kubectl -n istio-ingress get svc ingress-gw  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo http://${ip}/nginxa
echo http://${ip}/nginxb