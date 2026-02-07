# OpenShift Sandbox Deployment Guide

This guide is specifically for deploying the Stripe payment application to **OpenShift Sandbox** (Developer Sandbox for Red Hat OpenShift).

## What is OpenShift Sandbox?

OpenShift Sandbox is a free, time-limited OpenShift cluster that you can use for learning and development. It has some restrictions compared to full OpenShift:

- **Time limit**: 30-day sessions (renewable)
- **Resource limits**: Limited CPU and memory
- **Restricted permissions**: No cluster-admin access
- **Non-root containers**: Must run as non-root user with random UID
- **No custom SecurityContextConstraints**: Uses default restricted SCC

## Prerequisites

1. **OpenShift Sandbox Account**
   - Sign up at: https://developers.redhat.com/developer-sandbox
   - Free account, no credit card required
   - Verify your account via email

2. **Stripe Account**
   - Sign up at: https://stripe.com
   - Get your test API keys

3. **GitHub Account** (for source code)
   - Upload your code to GitHub first
   - See WINDOWS_PC_GUIDE.md for instructions

## Key Modifications for Sandbox

The following files have been modified to work in OpenShift Sandbox's restricted environment:

### ✅ Frontend Dockerfile
- Uses Red Hat UBI (Universal Base Image) with nginx
- Runs as user 1001 with group 0 permissions
- Uses `/opt/app-root/src` instead of `/usr/share/nginx/html`
- Compatible with random UID assignment

### ✅ Frontend nginx.conf
- Full nginx configuration (not just server block)
- Uses OpenShift-compatible paths
- Configured for port 8080

### ✅ Backend Dockerfile
- Runs as user 1001
- No custom user creation (OpenShift handles this)
- Group permissions set for random UID support

### ✅ Deployment Manifests
- Removed explicit securityContext (uses sandbox defaults)
- Reduced replicas to 1 (sandbox resource limits)
- No custom SecurityContextConstraints required

---

## Step-by-Step Deployment

### Step 1: Access Your Sandbox

1. **Login to OpenShift Sandbox**
   ```
   Go to: https://console.redhat.com/openshift/sandbox
   Click "Launch"
   ```

2. **Get Login Command**
   - Click on your username (top right)
   - Select "Copy login command"
   - Click "Display Token"
   - Copy the `oc login` command

3. **Login from Terminal**
   ```bash
   # Paste the command you copied
   oc login --token=sha256~xxxxx --server=https://api.sandbox.xxxx.openshiftapps.com:6443
   ```

### Step 2: Verify Your Project

OpenShift Sandbox automatically creates a project for you:

```bash
# Check your current project
oc project

# You should see something like:
# Using project "yourname-dev" on server "https://api.sandbox...".
```

### Step 3: Prepare Secrets

1. **Get your Stripe keys** from https://dashboard.stripe.com/test/apikeys

2. **Create secrets file locally** (DO NOT commit to Git):
   ```bash
   # Copy template
   cp openshift/secrets.yaml.template openshift/secrets.yaml
   
   # Edit the file (use notepad, nano, or vim)
   notepad openshift/secrets.yaml
   ```

3. **Add your actual Stripe keys**:
   ```yaml
   stringData:
     stripe-secret-key: "sk_test_YOUR_ACTUAL_SECRET_KEY"
     stripe-publishable-key: "pk_test_YOUR_ACTUAL_PUBLISHABLE_KEY"
     stripe-webhook-secret: "whsec_your_webhook_secret"  # Optional
   ```

4. **Create the secret in OpenShift**:
   ```bash
   oc apply -f openshift/secrets.yaml
   ```

### Step 4: Update ConfigMap

1. **Get your sandbox domain**:
   ```bash
   oc get route -n openshift-console console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console//'
   ```
   
   This will show something like: `.apps.sandbox-m2.ll9k.p1.openshiftapps.com`

2. **Edit configmap.yaml**:
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: app-config
   data:
     # Replace with your actual sandbox domain
     api-url: "https://api-yourname-dev.apps.sandbox-m2.ll9k.p1.openshiftapps.com"
     frontend-url: "https://stripe-payment-yourname-dev.apps.sandbox-m2.ll9k.p1.openshiftapps.com"
   ```

3. **Apply ConfigMap**:
   ```bash
   oc apply -f openshift/configmap.yaml
   ```

### Step 5: Build Images (Using Source-to-Image)

#### Option A: From GitHub (Recommended)

1. **Push your code to GitHub** (see WINDOWS_PC_GUIDE.md)

2. **Create ImageStreams**:
   ```bash
   oc create imagestream stripe-backend
   oc create imagestream stripe-frontend
   ```

3. **Build Backend**:
   ```bash
   oc new-build --name=stripe-backend \
     --image-stream=nodejs:18-ubi8 \
     --binary=true
   
   # Upload code from local backend directory
   oc start-build stripe-backend --from-dir=./backend --follow
   ```

4. **Build Frontend**:
   ```bash
   oc new-build --name=stripe-frontend \
     --strategy=docker \
     --binary=true
   
   # Upload code from local frontend directory
   oc start-build stripe-frontend --from-dir=./frontend --follow
   ```

#### Option B: From Git Repository

1. **Update BuildConfigs with your Git URL**:
   
   Edit `openshift/backend-buildconfig.yaml`:
   ```yaml
   spec:
     source:
       type: Git
       git:
         uri: https://github.com/YOUR-USERNAME/stripe-payment-app.git
         ref: main
       contextDir: backend
   ```

2. **Apply BuildConfigs**:
   ```bash
   oc apply -f openshift/backend-buildconfig.yaml
   oc apply -f openshift/frontend-buildconfig.yaml
   ```

3. **Start builds**:
   ```bash
   oc start-build stripe-backend-build --follow
   oc start-build stripe-frontend-build --follow
   ```

### Step 6: Update Deployment Images

Edit deployment files to use your built images:

**backend-deployment.yaml**:
```yaml
image: image-registry.openshift-image-registry.svc:5000/yourname-dev/stripe-backend:latest
```

**frontend-deployment.yaml**:
```yaml
image: image-registry.openshift-image-registry.svc:5000/yourname-dev/stripe-frontend:latest
```

Or use your project name:
```bash
# Get your project name
PROJECT_NAME=$(oc project -q)

# Update backend deployment
sed -i "s|your-registry/stripe-backend:latest|image-registry.openshift-image-registry.svc:5000/$PROJECT_NAME/stripe-backend:latest|g" openshift/backend-deployment.yaml

# Update frontend deployment
sed -i "s|your-registry/stripe-frontend:latest|image-registry.openshift-image-registry.svc:5000/$PROJECT_NAME/stripe-frontend:latest|g" openshift/frontend-deployment.yaml
```

### Step 7: Deploy Applications

```bash
# Deploy backend
oc apply -f openshift/backend-deployment.yaml

# Deploy frontend
oc apply -f openshift/frontend-deployment.yaml

# Check deployment status
oc get pods
oc logs -f deployment/stripe-backend
oc logs -f deployment/stripe-frontend
```

### Step 8: Create Routes

1. **Update routes with your project name**:
   ```bash
   PROJECT_NAME=$(oc project -q)
   SANDBOX_DOMAIN=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console//')
   
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
   ```

2. **Apply routes**:
   ```bash
   oc apply -f openshift/routes.yaml
   ```

3. **Get your URLs**:
   ```bash
   echo "Frontend: https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')"
   echo "Backend: https://$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')"
   ```

### Step 9: Verify Deployment

```bash
# Check all resources
oc get all

# Check pod status
oc get pods

# Check logs
oc logs deployment/stripe-backend
oc logs deployment/stripe-frontend

# Test backend health
curl https://$(oc get route stripe-backend-route -o jsonpath='{.spec.host}')/health

# Test frontend health
curl https://$(oc get route stripe-frontend-route -o jsonpath='{.spec.host}')/health
```

---

## Testing Your Application

1. **Get frontend URL**:
   ```bash
   oc get route stripe-frontend-route -o jsonpath='{.spec.host}'
   ```

2. **Open in browser**: `https://stripe-payment-yourname-dev.apps.sandbox...`

3. **Test payment** with Stripe test card:
   - Card number: `4242 4242 4242 4242`
   - Expiry: Any future date
   - CVC: Any 3 digits
   - ZIP: Any 5 digits

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod details
oc describe pod <pod-name>

# Check events
oc get events --sort-by='.lastTimestamp'

# Common issues:
# - Image pull errors: Check BuildConfig and image names
# - Resource limits: Sandbox has CPU/memory restrictions
# - Crash loops: Check application logs
```

### Build Failures

```bash
# Check build logs
oc logs bc/stripe-backend-build
oc logs bc/stripe-frontend-build

# Common issues:
# - npm install failures: Check package.json
# - Dockerfile errors: Verify Dockerfile syntax
# - Context directory: Ensure contextDir is correct
```

### Cannot Access Routes

```bash
# Verify routes exist
oc get routes

# Check route details
oc describe route stripe-frontend-route

# Verify services have endpoints
oc get endpoints

# Common issues:
# - Pod not ready: Check readiness probes
# - Service selector mismatch: Verify labels
# - TLS issues: Routes use edge termination
```

### Backend Cannot Connect to Stripe

```bash
# Check if secrets are loaded
oc get secret stripe-secrets

# Verify environment variables in pod
oc exec deployment/stripe-backend -- env | grep STRIPE

# Check backend logs for errors
oc logs deployment/stripe-backend

# Common issues:
# - Wrong API keys: Verify in Stripe dashboard
# - Test vs Live mode: Ensure using test keys
# - Network restrictions: Sandbox allows HTTPS outbound
```

### Frontend 404 or Cannot Find Backend

```bash
# Check if backend service is running
oc get svc backend-service

# Test backend from within cluster
oc run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl http://backend-service:8080/health

# Check CORS settings in backend
oc logs deployment/stripe-backend | grep CORS

# Common issues:
# - Wrong FRONTEND_URL in configmap
# - Backend service not exposed properly
# - CORS blocking requests
```

---

## Resource Limits in Sandbox

OpenShift Sandbox has the following limits:

- **CPU**: Up to 2 cores total
- **Memory**: Up to 7 GB total  
- **Storage**: Up to 15 GB
- **Projects**: 1 project per user
- **Time**: 30-day sessions (renewable)

**Recommendation**: Run 1 replica of each service to stay within limits.

---

## Updating Your Application

### Update Code and Redeploy

```bash
# Rebuild images after code changes
oc start-build stripe-backend --from-dir=./backend --follow
oc start-build stripe-frontend --from-dir=./frontend --follow

# Rollout restart (forces pod restart with new image)
oc rollout restart deployment/stripe-backend
oc rollout restart deployment/stripe-frontend

# Watch rollout status
oc rollout status deployment/stripe-backend
oc rollout status deployment/stripe-frontend
```

### Update Secrets

```bash
# Edit secrets
oc edit secret stripe-secrets

# Or delete and recreate
oc delete secret stripe-secrets
oc apply -f openshift/secrets.yaml

# Restart pods to pick up new secrets
oc rollout restart deployment/stripe-backend
```

### Update Configuration

```bash
# Edit configmap
oc edit configmap app-config

# Restart pods
oc rollout restart deployment/stripe-backend
oc rollout restart deployment/stripe-frontend
```

---

## Monitoring and Logs

### View Logs

```bash
# Real-time logs
oc logs -f deployment/stripe-backend
oc logs -f deployment/stripe-frontend

# Last 100 lines
oc logs deployment/stripe-backend --tail=100

# Specific pod
oc logs <pod-name>
```

### Check Resource Usage

```bash
# Pod resource usage
oc adm top pods

# Node resource usage
oc adm top nodes
```

### Access Pod Terminal

```bash
# Open shell in backend pod
oc rsh deployment/stripe-backend

# Run commands in pod
oc exec deployment/stripe-backend -- env
oc exec deployment/stripe-backend -- ls -la
```

---

## Clean Up

### Delete Everything

```bash
# Delete all app resources
oc delete all -l app=stripe-payment

# Delete secrets and configmaps
oc delete secret stripe-secrets
oc delete configmap app-config

# Verify deletion
oc get all
```

### Keep Resources but Stop Pods

```bash
# Scale to zero
oc scale deployment/stripe-backend --replicas=0
oc scale deployment/stripe-frontend --replicas=0

# Scale back up later
oc scale deployment/stripe-backend --replicas=1
oc scale deployment/stripe-frontend --replicas=1
```

---

## Important Notes for Sandbox

1. **Session Expiry**: Your sandbox session expires after 30 days of inactivity. You can renew it.

2. **No Persistent Storage**: Use external databases (like MongoDB Atlas, PostgreSQL on Heroku) for data persistence.

3. **Limited Resources**: Keep replicas at 1, optimize resource requests/limits.

4. **No Cluster Admin**: Cannot create custom SecurityContextConstraints or ClusterRoles.

5. **Automatic Sleep**: Pods may sleep after inactivity to save resources.

6. **Public Routes**: All routes are publicly accessible. Use authentication for production.

---

## Production Considerations

When moving from Sandbox to production OpenShift:

1. **Increase replicas** for high availability (2-3 replicas)
2. **Add persistent storage** for session data
3. **Configure autoscaling** with HorizontalPodAutoscaler
4. **Set up monitoring** with Prometheus and Grafana
5. **Use live Stripe keys** (switch from test to live)
6. **Configure proper DNS** and SSL certificates
7. **Implement rate limiting** and DDoS protection
8. **Add network policies** for security
9. **Set up CI/CD pipeline** with Jenkins or Tekton
10. **Configure backup strategy** for data

---

## Getting Help

- **Sandbox Support**: https://developers.redhat.com/developer-sandbox/get-started
- **OpenShift Docs**: https://docs.openshift.com
- **Stripe Support**: https://support.stripe.com
- **Community**: OpenShift forums and Stack Overflow

---

## Success Checklist

✅ OpenShift Sandbox account created and active  
✅ Stripe test API keys obtained  
✅ Code uploaded to GitHub  
✅ Secrets created in OpenShift  
✅ ConfigMap updated with correct URLs  
✅ Images built successfully  
✅ Deployments running (pods in Running state)  
✅ Services created and have endpoints  
✅ Routes created with HTTPS  
✅ Frontend accessible in browser  
✅ Backend health endpoint returns 200  
✅ Payment test successful with test card  

**Congratulations! Your Stripe payment app is running on OpenShift Sandbox!** 🎉
