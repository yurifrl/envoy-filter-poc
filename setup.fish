#!/usr/bin/env fish

function command_exists
    command -v $argv[1] >/dev/null 2>&1
end

if not command_exists minikube
    echo "minikube is not installed"
    exit 1
end

if not command_exists kubectl
    echo "kubectl is not installed"
    exit 1
end

if not command_exists go
    echo "go is not installed"
    echo "Please install Go from https://golang.org/doc/install"
    exit 1
end

function start_env
    echo "Starting minikube with required resources..."
    minikube delete 2>/dev/null || true
    minikube start --driver=docker \
        --memory=8192 \
        --cpus=4 \
        --kubernetes-version=v1.29.0

    echo "Installing Istio..."
    curl -L https://istio.io/downloadIstio | env ISTIO_VERSION=1.25.1 fish
    cd istio-*
    set -x PATH $PWD/bin $PATH

    istioctl install --set profile=demo -y

    kubectl label namespace default istio-injection=enabled --overwrite

    cd ..

    echo "Building target application..."
    set -l MINIKUBE_IP (minikube ip)
    set -x DOCKER_TLS_VERIFY 1
    set -x DOCKER_HOST "tcp://$MINIKUBE_IP:2376"
    set -x DOCKER_CERT_PATH "$HOME/.minikube/certs"
    set -x MINIKUBE_ACTIVE_DOCKERD minikube

    docker build -t target-app:latest ./target-app

    echo "Applying Kubernetes manifests..."
    kubectl apply -f k8s/filter-config.yaml
    kubectl apply -f k8s/deployment.yaml

    echo "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=target-app --timeout=60s

    echo "Waiting for Istio ingress gateway to be ready..."
    kubectl wait --for=condition=ready pod -l app=istio-ingressgateway -n istio-system --timeout=60s

    kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "NodePort"}}'

    set -l NODE_PORT (kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
    set -l INGRESS_IP (minikube ip)

    echo "Environment is ready!"
    echo "You can access the application at:"
    echo "http://$INGRESS_IP:$NODE_PORT"

    echo -e "\nDebug Information:"
    echo "Minikube IP: $INGRESS_IP"
    echo "NodePort: $NODE_PORT"
end

function stop_env
    echo "Cleaning up..."
    kubectl delete -f k8s/deployment.yaml 2>/dev/null || true
    kubectl delete -f k8s/plugin-config.yaml 2>/dev/null || true
    kubectl delete configmap lua-filter-plugin -n default 2>/dev/null || true
    minikube stop
    minikube delete
    rm -rf istio-* 2>/dev/null || true
    echo "Environment cleaned up!"
end

switch $argv[1]
    case start
        start_env
    case stop
        stop_env
    case '*'
        echo "Usage: $argv[0] {start|stop}"
        exit 1
end
