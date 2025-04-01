load('ext://helm_resource', 'helm_resource')

# Install Istio base and istiod
helm_resource(
    'istio-base',
    'https://istio-release.storage.googleapis.com/charts/base',
    flags=['--repo', 'https://istio-release.storage.googleapis.com/charts', '--create-namespace', '--namespace', 'istio-system']
)

helm_resource(
    'istiod',
    'https://istio-release.storage.googleapis.com/charts/istiod',
    flags=['--repo', 'https://istio-release.storage.googleapis.com/charts', '--namespace', 'istio-system'],
    resource_deps=['istio-base']
)

# Build Docker image
docker_build(
    'ghcr.io/yurifrl/envoy-filter-poc',
    'target-app',
    dockerfile='target-app/Dockerfile'
)

# Deploy Helm chart
helm_resource(
    'envoy-filter-poc',
    'helm/envoy-filter-poc',
    image_deps=['ghcr.io/yurifrl/envoy-filter-poc'],
    image_keys=[('image.repository', 'image.tag')],
    flags=['--create-namespace'],
    resource_deps=['istiod']
) 