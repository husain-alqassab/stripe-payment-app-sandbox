#!/bin/bash

# Stripe Payment Application - OpenShift Deployment Script
# This script automates the deployment of the Stripe payment application to OpenShift

set -e

echo "=========================================="
echo "Stripe Payment App - OpenShift Deployment"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    print_error "OpenShift CLI (oc) is not installed. Please install it first."
    exit 1
fi

# Check if logged in to OpenShift
if ! oc whoami &> /dev/null; then
    print_error "Not logged in to OpenShift. Please run 'oc login' first."
    exit 1
fi

print_status "Logged in as: $(oc whoami)"

# Prompt for project name
read -p "Enter project name (default: stripe-payment-app): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-stripe-payment-app}

# Check if project exists
if oc project "$PROJECT_NAME" &> /dev/null; then
    print_warning "Project $PROJECT_NAME already exists. Using existing project."
else
    print_status "Creating new project: $PROJECT_NAME"
    oc new-project "$PROJECT_NAME"
fi

# Check if secrets.yaml exists
if [ ! -f "openshift/secrets.yaml" ]; then
    print_warning "secrets.yaml not found. You need to create it from the template."
    echo ""
    echo "Steps:"
    echo "1. Copy the template: cp openshift/secrets.yaml.template openshift/secrets.yaml"
    echo "2. Edit openshift/secrets.yaml and add your Stripe API keys"
    echo "3. Run this script again"
    echo ""
    exit 1
fi

# Deploy secrets
print_status "Deploying secrets..."
oc apply -f openshift/secrets.yaml

# Get cluster domain
CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
print_status "Cluster domain: $CLUSTER_DOMAIN"

# Update ConfigMap with actual URLs
print_status "Updating ConfigMap with route URLs..."
cat > openshift/configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    app: stripe-payment
data:
  api-url: "https://api-${PROJECT_NAME}.${CLUSTER_DOMAIN}"
  frontend-url: "https://${PROJECT_NAME}.${CLUSTER_DOMAIN}"
EOF

oc apply -f openshift/configmap.yaml

# Update Routes with actual hostnames
print_status "Updating Routes with hostnames..."
cat > openshift/routes.yaml <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: stripe-frontend-route
  labels:
    app: stripe-payment
    component: frontend
  annotations:
    haproxy.router.openshift.io/timeout: 30s
spec:
  host: ${PROJECT_NAME}.${CLUSTER_DOMAIN}
  to:
    kind: Service
    name: frontend-service
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: stripe-backend-route
  labels:
    app: stripe-payment
    component: backend
  annotations:
    haproxy.router.openshift.io/timeout: 60s
spec:
  host: api-${PROJECT_NAME}.${CLUSTER_DOMAIN}
  to:
    kind: Service
    name: backend-service
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
EOF

# Ask user which deployment method to use
echo ""
echo "Choose deployment method:"
echo "1. Build from Git repository (Source-to-Image)"
echo "2. Use local Docker images"
read -p "Enter choice (1 or 2): " DEPLOY_METHOD

if [ "$DEPLOY_METHOD" = "1" ]; then
    # Git repository deployment
    read -p "Enter your Git repository URL: " GIT_URL
    read -p "Enter branch name (default: main): " GIT_BRANCH
    GIT_BRANCH=${GIT_BRANCH:-main}
    
    # Update BuildConfigs
    print_status "Creating BuildConfigs..."
    
    cat > openshift/backend-buildconfig.yaml <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: stripe-backend-build
  labels:
    app: stripe-payment
    component: backend
spec:
  source:
    type: Git
    git:
      uri: $GIT_URL
      ref: $GIT_BRANCH
    contextDir: backend
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
  output:
    to:
      kind: ImageStreamTag
      name: stripe-backend:latest
  triggers:
  - type: ConfigChange
  - type: ImageChange
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: stripe-backend
  labels:
    app: stripe-payment
    component: backend
spec:
  lookupPolicy:
    local: true
EOF

    cat > openshift/frontend-buildconfig.yaml <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: stripe-frontend-build
  labels:
    app: stripe-payment
    component: frontend
spec:
  source:
    type: Git
    git:
      uri: $GIT_URL
      ref: $GIT_BRANCH
    contextDir: frontend
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
  output:
    to:
      kind: ImageStreamTag
      name: stripe-frontend:latest
  triggers:
  - type: ConfigChange
  - type: ImageChange
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: stripe-frontend
  labels:
    app: stripe-payment
    component: frontend
spec:
  lookupPolicy:
    local: true
EOF

    oc apply -f openshift/backend-buildconfig.yaml
    oc apply -f openshift/frontend-buildconfig.yaml
    
    print_status "Starting builds..."
    oc start-build stripe-backend-build
    oc start-build stripe-frontend-build
    
    print_warning "Builds started. This may take several minutes..."
    print_status "Waiting for backend build to complete..."
    oc wait --for=condition=Complete build/stripe-backend-build-1 --timeout=600s
    print_status "Waiting for frontend build to complete..."
    oc wait --for=condition=Complete build/stripe-frontend-build-1 --timeout=600s
    
    # Update deployments to use ImageStreams
    IMAGE_BACKEND="stripe-backend:latest"
    IMAGE_FRONTEND="stripe-frontend:latest"
    
elif [ "$DEPLOY_METHOD" = "2" ]; then
    # Local Docker images
    print_status "Building Docker images locally..."
    
    docker build -t stripe-backend:latest backend/
    docker build -t stripe-frontend:latest frontend/
    
    print_status "Pushing images to OpenShift registry..."
    
    # Get registry URL
    REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    
    if [ -z "$REGISTRY" ]; then
        print_error "Cannot access OpenShift internal registry. Please use method 1 (Git) instead."
        exit 1
    fi
    
    # Login to registry
    docker login -u $(oc whoami) -p $(oc whoami -t) $REGISTRY
    
    # Tag and push
    docker tag stripe-backend:latest $REGISTRY/$PROJECT_NAME/stripe-backend:latest
    docker tag stripe-frontend:latest $REGISTRY/$PROJECT_NAME/stripe-frontend:latest
    
    docker push $REGISTRY/$PROJECT_NAME/stripe-backend:latest
    docker push $REGISTRY/$PROJECT_NAME/stripe-frontend:latest
    
    IMAGE_BACKEND="image-registry.openshift-image-registry.svc:5000/$PROJECT_NAME/stripe-backend:latest"
    IMAGE_FRONTEND="image-registry.openshift-image-registry.svc:5000/$PROJECT_NAME/stripe-frontend:latest"
else
    print_error "Invalid choice. Exiting."
    exit 1
fi

# Update deployment files with correct image references
print_status "Updating deployment configurations..."

# Update backend deployment
sed "s|image: .*|image: $IMAGE_BACKEND|g" openshift/backend-deployment.yaml > openshift/backend-deployment-tmp.yaml
mv openshift/backend-deployment-tmp.yaml openshift/backend-deployment.yaml

# Update frontend deployment
sed "s|image: .*|image: $IMAGE_FRONTEND|g" openshift/frontend-deployment.yaml > openshift/frontend-deployment-tmp.yaml
mv openshift/frontend-deployment-tmp.yaml openshift/frontend-deployment.yaml

# Deploy applications in correct order
print_status "Deploying backend first..."
oc apply -f openshift/backend-deployment.yaml

print_status "Waiting for backend to be ready (this prevents frontend DNS issues)..."
oc rollout status deployment/stripe-backend --timeout=300s

print_status "Backend is ready! Now deploying frontend..."
oc apply -f openshift/frontend-deployment.yaml

print_status "Creating routes..."
oc apply -f openshift/routes.yaml

# Wait for frontend deployment
print_status "Waiting for frontend to be ready..."
oc rollout status deployment/stripe-frontend --timeout=300s

# Get routes
FRONTEND_URL=$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')
BACKEND_URL=$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')

echo ""
echo "=========================================="
print_status "Deployment Complete!"
echo "=========================================="
echo ""
echo "Frontend URL: https://${FRONTEND_URL}"
echo "Backend URL:  https://${BACKEND_URL}"
echo ""
echo "Test the application:"
echo "1. Open https://${FRONTEND_URL} in your browser"
echo "2. Use test card: 4242 4242 4242 4242"
echo ""
print_warning "Remember: This is using Stripe TEST mode"
echo ""
