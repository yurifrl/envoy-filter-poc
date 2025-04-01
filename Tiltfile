load('ext://helm_resource', 'helm_resource')
load('ext://docker_build', 'docker_build')

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
    flags=['--create-namespace']
) 