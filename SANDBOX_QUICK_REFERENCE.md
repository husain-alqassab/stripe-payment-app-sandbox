# OpenShift Sandbox - Quick Command Reference

## 🚀 Quick Deploy (Copy & Paste)

### Prerequisites
```bash
# 1. Login to OpenShift Sandbox (get command from console)
oc login --token=sha256~xxxxx --server=https://api.sandbox.xxxx

# 2. Verify project
oc project
```

### One-Time Setup
```bash
# Get your project and domain info
export PROJECT_NAME=$(oc project -q)
export SANDBOX_DOMAIN=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console//')

echo "Your project: $PROJECT_NAME"
echo "Your domain: $SANDBOX_DOMAIN"
```

### Deploy in 5 Minutes

```bash
# 1. Create secrets (edit with your Stripe keys first!)
cp openshift/secrets.yaml.template openshift/secrets.yaml
# Edit secrets.yaml with your actual Stripe keys
oc apply -f openshift/secrets.yaml

# 2. Update and create ConfigMap
cat > openshift/configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  api-url: "https://api-${PROJECT_NAME}${SANDBOX_DOMAIN}"
  frontend-url: "https://stripe-payment-${PROJECT_NAME}${SANDBOX_DOMAIN}"
EOF
oc apply -f openshift/configmap.yaml

# 3. Create ImageStreams
oc create imagestream stripe-backend
oc create imagestream stripe-frontend

# 4. Build Backend
oc new-build --name=stripe-backend --image-stream=nodejs:18-ubi8 --binary=true
oc start-build stripe-backend --from-dir=./backend --follow

# 5. Build Frontend
oc new-build --name=stripe-frontend --strategy=docker --binary=true
oc start-build stripe-frontend --from-dir=./frontend --follow

# 6. Update deployment image references
sed -i "s|your-registry/stripe-backend:latest|image-registry.openshift-image-registry.svc:5000/$PROJECT_NAME/stripe-backend:latest|g" openshift/backend-deployment.yaml
sed -i "s|your-registry/stripe-frontend:latest|image-registry.openshift-image-registry.svc:5000/$PROJECT_NAME/stripe-frontend:latest|g" openshift/frontend-deployment.yaml

# 7. Deploy applications
oc apply -f openshift/backend-deployment.yaml
oc apply -f openshift/frontend-deployment.yaml

# 8. Create routes
cat > openshift/routes.yaml <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: stripe-frontend-route
spec:
  host: stripe-payment-${PROJECT_NAME}${SANDBOX_DOMAIN}
  to:
    kind: Service
    name: frontend-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: stripe-backend-route
spec:
  host: api-${PROJECT_NAME}${SANDBOX_DOMAIN}
  to:
    kind: Service
    name: backend-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
oc apply -f openshift/routes.yaml

# 9. Get your application URL
echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "Frontend URL: https://stripe-payment-${PROJECT_NAME}${SANDBOX_DOMAIN}"
echo "Backend URL:  https://api-${PROJECT_NAME}${SANDBOX_DOMAIN}"
echo ""
echo "Test with card: 4242 4242 4242 4242"
```

---

## 📋 Essential Commands

### Status Checks
```bash
# View all resources
oc get all

# Check pods
oc get pods
oc get pods -w  # Watch mode

# Check services
oc get svc

# Check routes
oc get routes

# Get application URLs
echo "Frontend: https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')"
echo "Backend: https://$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')"
```

### View Logs
```bash
# Backend logs (live)
oc logs -f deployment/stripe-backend

# Frontend logs (live)
oc logs -f deployment/stripe-frontend

# Last 50 lines
oc logs deployment/stripe-backend --tail=50

# Specific pod
oc logs <pod-name>
```

### Troubleshooting
```bash
# Describe resources
oc describe pod <pod-name>
oc describe deployment stripe-backend
oc describe svc backend-service

# Check events
oc get events --sort-by='.lastTimestamp'

# Check resource usage
oc adm top pods

# Access pod shell
oc rsh deployment/stripe-backend

# Run command in pod
oc exec deployment/stripe-backend -- env
```

### Build Commands
```bash
# Check builds
oc get builds

# Watch build
oc logs -f bc/stripe-backend-build

# Start new build
oc start-build stripe-backend --from-dir=./backend --follow
oc start-build stripe-frontend --from-dir=./frontend --follow

# Cancel build
oc cancel-build <build-name>
```

### Update & Restart
```bash
# Restart deployments (after code/config changes)
oc rollout restart deployment/stripe-backend
oc rollout restart deployment/stripe-frontend

# Watch rollout
oc rollout status deployment/stripe-backend
oc rollout status deployment/stripe-frontend

# Rollback
oc rollout undo deployment/stripe-backend
```

### Scaling
```bash
# Scale up
oc scale deployment/stripe-backend --replicas=2

# Scale down (to save resources)
oc scale deployment/stripe-backend --replicas=0

# Autoscale
oc autoscale deployment/stripe-backend --min=1 --max=3 --cpu-percent=70
```

### Secrets & Config
```bash
# View secrets (base64 encoded)
oc get secret stripe-secrets -o yaml

# Edit secret
oc edit secret stripe-secrets

# Delete and recreate
oc delete secret stripe-secrets
oc apply -f openshift/secrets.yaml

# View ConfigMap
oc get configmap app-config -o yaml

# Edit ConfigMap
oc edit configmap app-config
```

### Clean Up
```bash
# Delete specific resources
oc delete deployment stripe-backend
oc delete service backend-service
oc delete route stripe-backend-route

# Delete all app resources
oc delete all -l app=stripe-payment

# Delete secrets and configs
oc delete secret stripe-secrets
oc delete configmap app-config

# Delete everything
oc delete all,secret,configmap -l app=stripe-payment
```

---

## 🔧 Testing Commands

### Test Backend
```bash
# Health check
curl https://$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')/health

# Get config
curl https://$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')/api/config

# List products
curl https://$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')/api/products
```

### Test Frontend
```bash
# Health check
curl https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')/health

# Open in browser (Linux)
xdg-open https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')

# Open in browser (Mac)
open https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')

# Open in browser (Windows)
start https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')
```

### Test from Inside Cluster
```bash
# Run test pod
oc run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl http://backend-service:8080/health

# Test backend from frontend pod
oc exec deployment/stripe-frontend -- curl http://backend-service:8080/health
```

---

## 🚨 Common Issues & Fixes

### Pods CrashLoopBackOff
```bash
# Check logs
oc logs <pod-name>
oc logs <pod-name> --previous  # Previous container logs

# Common causes:
# - Missing environment variables
# - Wrong secrets
# - Application errors

# Fix: Check secrets and environment
oc describe pod <pod-name>
```

### ImagePullBackOff
```bash
# Check image name
oc describe pod <pod-name>

# List images
oc get imagestream

# Rebuild
oc start-build stripe-backend --follow
```

### Route Not Working
```bash
# Check route
oc get route
oc describe route stripe-frontend-route

# Check service
oc get svc
oc describe svc frontend-service

# Check endpoints
oc get endpoints frontend-service
```

### Out of Memory/CPU
```bash
# Check resource usage
oc adm top pods

# Reduce resources in deployment
oc edit deployment stripe-backend

# Or scale down
oc scale deployment/stripe-backend --replicas=0
```

---

## 📊 Monitoring

### Resource Usage
```bash
# Pod metrics
oc adm top pods

# Deployment metrics
oc adm top pods -l app=stripe-payment

# Events
oc get events --sort-by='.lastTimestamp' --field-selector involvedObject.kind=Pod
```

### Logs Export
```bash
# Save logs to file
oc logs deployment/stripe-backend > backend.log
oc logs deployment/stripe-frontend > frontend.log

# Follow multiple pods
oc logs -f -l app=stripe-payment
```

---

## 💡 Pro Tips

### Save Typing with Aliases
```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='oc'
alias kgp='oc get pods'
alias kgs='oc get svc'
alias kgr='oc get routes'
alias kl='oc logs -f'
alias kd='oc describe'
```

### Quick URL Access
```bash
# Save URLs as variables
export FRONTEND_URL=$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')
export BACKEND_URL=$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')

echo $FRONTEND_URL
echo $BACKEND_URL
```

### Watch Resources
```bash
# Auto-refresh every 2 seconds
watch -n 2 oc get pods

# Watch specific deployment
oc get pods -w -l component=backend
```

---

## 🎯 Deployment Checklist

Before deploying, verify:

- [ ] Logged into OpenShift Sandbox
- [ ] Stripe API keys obtained (test mode)
- [ ] secrets.yaml created with real keys
- [ ] Code uploaded to GitHub (optional)
- [ ] BuildConfigs updated (if using Git)

After deploying, verify:

- [ ] All pods in Running state
- [ ] Services have endpoints
- [ ] Routes accessible (returns 200)
- [ ] Backend /health returns "healthy"
- [ ] Frontend loads in browser
- [ ] Test payment works (4242 4242 4242 4242)

---

## 📞 Get Help

```bash
# Describe issues
oc describe pod <pod-name>
oc get events

# Export configuration
oc get deployment stripe-backend -o yaml > backend-debug.yaml

# Check API server
oc version
oc whoami
oc project
```

---

**Need more details? See OPENSHIFT_SANDBOX_GUIDE.md for the full guide.**
