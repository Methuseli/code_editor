#!/bin/bash

set -e

ENVIRONMENT=${1:-staging}
NAMESPACE="collaborative-editor"

echo "🚀 Deploying Collaborative Code Editor to $ENVIRONMENT..."

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Check required tools
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ docker is required but not installed. Aborting." >&2; exit 1; }

# Set environment variables
if [[ "$ENVIRONMENT" == "production" ]]; then
    REGISTRY="ghcr.io/collaborative-editor"
    CONTEXT="collaborative-editor-prod"
    REPLICAS_BACKEND=3
    REPLICAS_FRONTEND=3
else
    REGISTRY="ghcr.io/collaborative-editor"
    CONTEXT="collaborative-editor-staging"
    REPLICAS_BACKEND=2
    REPLICAS_FRONTEND=2
fi

echo "📋 Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   Registry: $REGISTRY"
echo "   Context: $CONTEXT"
echo "   Backend replicas: $REPLICAS_BACKEND"
echo "   Frontend replicas: $REPLICAS_FRONTEND"

# Build and push images
echo "🔨 Building Docker images..."
docker build -f docker/frontend.Dockerfile -t $REGISTRY/frontend:latest .
docker build -f docker/backend.Dockerfile -t $REGISTRY/backend:latest .

echo "📤 Pushing images to registry..."
docker push $REGISTRY/frontend:latest
docker push $REGISTRY/backend:latest

# Switch kubectl context
if kubectl config get-contexts | grep -q "$CONTEXT"; then
    echo "🔄 Switching to kubectl context: $CONTEXT"
    kubectl config use-context $CONTEXT
else
    echo "⚠️  Context $CONTEXT not found, using current context"
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Update image references in Kubernetes manifests
echo "🔧 Updating Kubernetes manifests..."
sed -i.bak "s|collaborative-editor/frontend:latest|$REGISTRY/frontend:latest|g" k8s/frontend.yaml
sed -i.bak "s|collaborative-editor/backend:latest|$REGISTRY/backend:latest|g" k8s/backend.yaml

# Update replica counts for environment
sed -i.bak "s|replicas: [0-9]*|replicas: $REPLICAS_BACKEND|g" k8s/backend.yaml
sed -i.bak "s|replicas: [0-9]*|replicas: $REPLICAS_FRONTEND|g" k8s/frontend.yaml

# Deploy infrastructure components first
echo "🗄️  Deploying infrastructure..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/redis.yaml

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/redis -n $NAMESPACE

# Deploy application components
echo "🚀 Deploying applications..."
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for application deployments..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n $NAMESPACE

# Run database migrations
echo "🗄️  Running database migrations..."
kubectl exec -n $NAMESPACE deployment/backend -- bin/collaborative_editor eval "CollaborativeEditor.Release.migrate"

# Deploy ingress
echo "🌐 Deploying ingress..."
kubectl apply -f k8s/ingress.yaml

# Restore original manifests
echo "🔄 Restoring original manifests..."
mv k8s/frontend.yaml.bak k8s/frontend.yaml
mv k8s/backend.yaml.bak k8s/backend.yaml

# Display deployment status
echo "📊 Deployment Status:"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get ingress -n $NAMESPACE

# Run health checks
echo "🏥 Running health checks..."
if kubectl get pods -n $NAMESPACE | grep -q "Running"; then
    echo "✅ Pods are running"
else
    echo "❌ Some pods are not running"
    kubectl get pods -n $NAMESPACE
    exit 1
fi

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
sleep 30

# Get ingress endpoint
INGRESS_IP=$(kubectl get ingress collaborative-editor-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ -z "$INGRESS_IP" ]]; then
    INGRESS_IP=$(kubectl get ingress collaborative-editor-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

if [[ -n "$INGRESS_IP" ]]; then
    echo "🌍 Application is accessible at: https://$INGRESS_IP"
else
    echo "⚠️  Ingress IP not yet available, check status with: kubectl get ingress -n $NAMESPACE"
fi

echo "✅ Deployment to $ENVIRONMENT completed successfully!"

# Show logs for troubleshooting if needed
echo ""
echo "📝 To view logs:"
echo "   Backend: kubectl logs -f deployment/backend -n $NAMESPACE"
echo "   Frontend: kubectl logs -f deployment/frontend -n $NAMESPACE"
echo ""
echo "🔧 To debug:"
echo "   kubectl describe pods -n $NAMESPACE"
echo "   kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"