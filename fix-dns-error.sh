#!/bin/bash

# Quick Fix Script for "host not found in upstream backend-service" Error
# Run this script if you're experiencing nginx DNS issues

set -e

echo "=========================================="
echo "  Fixing Nginx Backend Service DNS Issue"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if oc is available
if ! command -v oc &> /dev/null; then
    print_error "OpenShift CLI (oc) not found. Please install it first."
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    print_error "Not logged in to OpenShift. Please run 'oc login' first."
    exit 1
fi

print_status "Logged in as: $(oc whoami)"
print_status "Current project: $(oc project -q)"

echo ""
echo "Step 1: Checking current deployment status..."
echo ""

# Check if backend exists
if oc get deployment stripe-backend &> /dev/null; then
    print_status "Backend deployment exists"
    BACKEND_READY=$(oc get deployment stripe-backend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [ "$BACKEND_READY" -gt 0 ]; then
        print_status "Backend is running ($BACKEND_READY pods ready)"
    else
        print_warning "Backend exists but no pods are ready"
    fi
else
    print_warning "Backend deployment not found"
fi

# Check if frontend exists
if oc get deployment stripe-frontend &> /dev/null; then
    print_status "Frontend deployment exists"
    
    # Check for errors
    FRONTEND_STATUS=$(oc get pods -l component=frontend -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
    if [ "$FRONTEND_STATUS" = "Running" ]; then
        print_status "Frontend is running"
    else
        print_warning "Frontend status: $FRONTEND_STATUS"
        
        # Check logs for the error
        if oc logs -l component=frontend 2>/dev/null | grep -q "host not found in upstream"; then
            print_error "Found 'host not found in upstream' error in frontend logs"
            echo ""
            echo "Applying fix..."
        fi
    fi
else
    print_warning "Frontend deployment not found"
fi

echo ""
echo "Step 2: Applying fixes..."
echo ""

# Fix 1: Ensure backend is deployed and ready
if ! oc get deployment stripe-backend &> /dev/null; then
    print_status "Deploying backend..."
    if [ -f "openshift/backend-deployment.yaml" ]; then
        oc apply -f openshift/backend-deployment.yaml
    else
        print_error "openshift/backend-deployment.yaml not found"
        echo "Please ensure you're in the stripe-payment-app directory"
        exit 1
    fi
fi

print_status "Waiting for backend to be ready..."
oc rollout status deployment/stripe-backend --timeout=300s

# Fix 2: Delete and recreate frontend to pick up backend service
if oc get deployment stripe-frontend &> /dev/null; then
    print_status "Restarting frontend deployment..."
    oc rollout restart deployment/stripe-frontend
    oc rollout status deployment/stripe-frontend --timeout=300s
else
    print_status "Deploying frontend..."
    if [ -f "openshift/frontend-deployment.yaml" ]; then
        oc apply -f openshift/frontend-deployment.yaml
        oc rollout status deployment/stripe-frontend --timeout=300s
    else
        print_error "openshift/frontend-deployment.yaml not found"
        exit 1
    fi
fi

echo ""
echo "Step 3: Verifying fix..."
echo ""

# Verify backend service exists
if oc get svc backend-service &> /dev/null; then
    BACKEND_IP=$(oc get svc backend-service -o jsonpath='{.spec.clusterIP}')
    print_status "Backend service exists at: $BACKEND_IP"
else
    print_error "Backend service not found!"
    exit 1
fi

# Verify frontend can resolve backend
sleep 5  # Wait a bit for pods to stabilize

FRONTEND_POD=$(oc get pods -l component=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$FRONTEND_POD" ]; then
    print_status "Testing DNS resolution from frontend pod..."
    
    if oc exec $FRONTEND_POD -- nslookup backend-service &> /dev/null; then
        print_status "Frontend can resolve backend-service DNS ✓"
    else
        print_warning "Frontend cannot resolve backend-service DNS"
        echo "This might resolve itself in a few moments..."
    fi
    
    # Test HTTP connection
    print_status "Testing HTTP connection to backend..."
    if oc exec $FRONTEND_POD -- wget -q -O- http://backend-service:8080/health &> /dev/null; then
        print_status "Frontend can reach backend HTTP endpoint ✓"
    else
        print_warning "Frontend cannot reach backend HTTP endpoint yet"
        echo "The backend might still be starting up..."
    fi
fi

# Check for errors in logs
echo ""
print_status "Checking logs for errors..."
if oc logs -l component=frontend --tail=20 2>/dev/null | grep -q "host not found in upstream"; then
    print_error "Still seeing DNS errors in logs"
    echo ""
    echo "Recent frontend logs:"
    oc logs -l component=frontend --tail=10
    echo ""
    print_warning "The frontend container may need to be recreated"
    echo "Try running: oc delete pod -l component=frontend"
else
    print_status "No DNS errors found in recent logs ✓"
fi

echo ""
echo "=========================================="
echo "          Status Summary"
echo "=========================================="
echo ""

# Final status
oc get pods -l app=stripe-payment

echo ""
FRONTEND_URL=$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "Not configured")
BACKEND_URL=$(oc get route stripe-backend-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "Not configured")

echo "Frontend URL: https://${FRONTEND_URL}"
echo "Backend URL:  https://${BACKEND_URL}"
echo ""

# Check if both are running
BACKEND_RUNNING=$(oc get deployment stripe-backend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
FRONTEND_RUNNING=$(oc get deployment stripe-frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "$BACKEND_RUNNING" -gt 0 ] && [ "$FRONTEND_RUNNING" -gt 0 ]; then
    print_status "Both services are running! ✓"
    echo ""
    echo "Try accessing: https://${FRONTEND_URL}"
    echo ""
    print_status "Fix applied successfully! 🎉"
else
    print_warning "Services might still be starting up..."
    echo ""
    echo "Monitor progress with:"
    echo "  oc get pods -w"
    echo ""
    echo "View logs with:"
    echo "  oc logs -l component=frontend -f"
    echo "  oc logs -l component=backend -f"
fi

echo ""
