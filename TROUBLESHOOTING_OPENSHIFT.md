# OpenShift Deployment - Troubleshooting Guide

## ❌ Error: "host not found in upstream backend-service"

This is a common error when deploying to OpenShift/Kubernetes. Here's how to fix it.

---

## 🔍 What's Happening?

The **frontend container is starting before the backend service is created**, causing nginx to fail because it can't resolve `backend-service` hostname.

---

## ✅ Solutions (Choose One)

### **Solution 1: Fix Nginx Configuration (RECOMMENDED)**

Replace your `frontend/nginx.conf` with the improved version:

**File: `frontend/nginx.conf`**
```nginx
server {
    listen 8080;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # API proxy to backend with dynamic DNS
    location /api/ {
        # Use variable for dynamic DNS resolution
        set $backend http://backend-service:8080;
        proxy_pass $backend;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # OpenShift DNS resolver
        resolver 172.30.0.10 valid=10s;
        resolver_timeout 5s;
        
        # Error handling for when backend is unavailable
        proxy_intercept_errors on;
        error_page 502 503 504 = @backend_unavailable;
    }
    
    # Fallback response when backend is down
    location @backend_unavailable {
        default_type application/json;
        return 503 '{"error": "Backend service temporarily unavailable"}';
    }

    # Static files with caching
    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # React app - SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    error_page 404 /index.html;
}
```

**Key Changes:**
- ✅ Uses variable `set $backend` for dynamic DNS
- ✅ Adds OpenShift DNS resolver
- ✅ Graceful error handling when backend is unavailable
- ✅ Allows nginx to start even if backend doesn't exist yet

---

### **Solution 2: Deploy Backend First**

Ensure backend is running before deploying frontend:

```bash
# Deploy backend first
oc apply -f openshift/backend-deployment.yaml

# Wait for backend to be ready
oc wait --for=condition=available deployment/stripe-backend --timeout=300s

# Then deploy frontend
oc apply -f openshift/frontend-deployment.yaml
```

---

### **Solution 3: Add Init Container (Advanced)**

Add an init container that waits for backend service to exist:

**Update `frontend-deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stripe-frontend
spec:
  template:
    spec:
      # Add init container
      initContainers:
      - name: wait-for-backend
        image: busybox:1.35
        command: ['sh', '-c', 'until nslookup backend-service; do echo waiting for backend-service; sleep 2; done']
      
      # Then regular containers
      containers:
      - name: frontend
        image: your-registry/stripe-frontend:latest
        # ... rest of config
```

---

## 🔧 Quick Fix Steps

### **If You're Seeing This Error Right Now:**

**Step 1: Check if backend is running**
```bash
oc get pods

# You should see:
# stripe-backend-xxxxx    1/1   Running
# stripe-frontend-xxxxx   0/1   CrashLoopBackOff or Error
```

**Step 2: If backend is NOT running, deploy it first**
```bash
oc apply -f openshift/backend-deployment.yaml
oc wait --for=condition=available deployment/stripe-backend --timeout=300s
```

**Step 3: Update nginx.conf**
```bash
# Update the nginx.conf file with Solution 1 above
# Then rebuild frontend image

cd frontend
docker build -t stripe-frontend:latest .

# Push to registry
REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
docker login -u $(oc whoami) -p $(oc whoami -t) $REGISTRY
docker tag stripe-frontend:latest $REGISTRY/stripe-payment-app/stripe-frontend:latest
docker push $REGISTRY/stripe-payment-app/stripe-frontend:latest
```

**Step 4: Restart frontend deployment**
```bash
oc rollout restart deployment/stripe-frontend
oc rollout status deployment/stripe-frontend
```

---

## 🔍 Verify the Fix

**Check pod logs:**
```bash
# Frontend logs should no longer show nginx error
oc logs deployment/stripe-frontend

# Should see:
# "Configuration complete; ready for start up"
# No "host not found" errors
```

**Check services:**
```bash
oc get svc

# Should show:
# backend-service    ClusterIP   10.x.x.x   <none>   8080/TCP
# frontend-service   ClusterIP   10.x.x.x   <none>   8080/TCP
```

**Test the connection:**
```bash
# Get frontend pod name
FRONTEND_POD=$(oc get pods -l component=frontend -o jsonpath='{.items[0].metadata.name}')

# Test DNS resolution from frontend pod
oc exec $FRONTEND_POD -- nslookup backend-service

# Should return an IP address
```

---

## 🚨 Common Related Issues

### **Issue: Backend service not found**

**Check:**
```bash
oc get svc backend-service

# If not found:
oc apply -f openshift/backend-deployment.yaml
```

### **Issue: DNS resolver not working**

**For OpenShift, try different resolver IPs:**
```nginx
# Option 1: OpenShift default
resolver 172.30.0.10 valid=10s;

# Option 2: Cluster DNS
resolver kube-dns.kube-system.svc.cluster.local valid=10s;

# Option 3: Get actual cluster DNS
# Run: oc get svc -n kube-system
# Look for kube-dns or coredns service IP
```

### **Issue: Frontend still crashing**

**Check all logs:**
```bash
# View all events
oc get events --sort-by='.lastTimestamp'

# Describe frontend pod
oc describe pod -l component=frontend

# Check if backend is actually ready
oc get pods -l component=backend
```

---

## 📋 Prevention Checklist

For future deployments:

- [ ] Always deploy backend before frontend
- [ ] Use dynamic DNS resolution in nginx
- [ ] Add proper error handling in nginx config
- [ ] Use init containers for dependencies
- [ ] Add readiness/liveness probes
- [ ] Test locally with docker-compose first

---

## 🔄 Correct Deployment Order

**Always follow this order:**

```bash
# 1. Secrets and ConfigMaps
oc apply -f openshift/secrets.yaml
oc apply -f openshift/configmap.yaml

# 2. Backend (with service)
oc apply -f openshift/backend-deployment.yaml

# 3. Wait for backend to be ready
oc wait --for=condition=available deployment/stripe-backend --timeout=300s

# 4. Frontend (depends on backend service)
oc apply -f openshift/frontend-deployment.yaml

# 5. Routes
oc apply -f openshift/routes.yaml

# 6. Verify
oc get pods
oc get svc
oc get routes
```

---

## 💡 Alternative: Environment Variables Instead of Proxy

If nginx proxy continues to cause issues, you can configure the frontend to call the backend directly via environment variables:

**Update `frontend-deployment.yaml`:**
```yaml
env:
- name: REACT_APP_API_URL
  value: "https://api-stripe-payment.apps.your-cluster.example.com"
```

**Update `frontend/src/App.js`:**
```javascript
// Use full backend URL instead of /api
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';
```

**Remove proxy from nginx.conf:**
Just remove the `/api/` location block entirely.

---

## 🆘 Still Having Issues?

**Get detailed diagnostics:**

```bash
# Check all resources
oc get all

# View all pod logs
oc logs -l app=stripe-payment --all-containers=true

# Check network policies
oc get networkpolicies

# Verify service endpoints
oc get endpoints backend-service
oc get endpoints frontend-service

# Test connectivity from frontend to backend
FRONTEND_POD=$(oc get pods -l component=frontend -o jsonpath='{.items[0].metadata.name}')
oc exec $FRONTEND_POD -- curl -v http://backend-service:8080/health
```

**Common causes:**
1. ❌ Backend not deployed yet
2. ❌ Service names don't match
3. ❌ Wrong namespace/project
4. ❌ Network policies blocking traffic
5. ❌ DNS not properly configured

---

## ✅ Success Indicators

You've fixed the issue when:

1. ✅ `oc get pods` shows both frontend and backend as "Running"
2. ✅ No nginx errors in frontend logs
3. ✅ Frontend can reach backend health endpoint
4. ✅ Routes are accessible from browser
5. ✅ No CrashLoopBackOff status

---

## 📞 Need More Help?

If you're still stuck:

1. Share the output of: `oc get all`
2. Share frontend pod logs: `oc logs -l component=frontend`
3. Share backend pod logs: `oc logs -l component=backend`
4. Check OpenShift console for visual debugging
