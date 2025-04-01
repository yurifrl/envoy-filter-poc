#!/usr/bin/env fish

echo "Testing plugin..."
set -l NODE_PORT (kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
set -l MINIKUBE_IP (minikube ip)
curl -H "Authorization: test" http://$MINIKUBE_IP:$NODE_PORT/plugin

echo "Testing filter..."
curl -H "Authorization: test" http://$MINIKUBE_IP:$NODE_PORT/filter
