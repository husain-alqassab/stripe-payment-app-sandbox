# Stripe Payment Application - OpenShift Deployment Guide

A full-stack customer-facing payment application with Stripe integration, configured for deployment on OpenShift.

## Architecture

- **Frontend**: React application with Stripe Elements
- **Backend**: Node.js/Express API with Stripe SDK
- **Platform**: OpenShift with containerized deployments

## Prerequisites

1. **OpenShift Cluster**: Access to an OpenShift 4.x cluster
2. **Stripe Account**: Create account at https://stripe.com
3. **CLI Tools**: 
   - `oc` (OpenShift CLI)
   - `docker` or `podman`
4. **Git Repository**: (Optional) For automated builds

## Project Structure

```
stripe-payment-app/
├── backend/
│   ├── server.js           # Express server with Stripe integration
│   ├── package.json        # Backend dependencies
│   └── Dockerfile          # Backend container image
├── frontend/
│   ├── src/
│   │   ├── App.js         # Main React application
│   │   ├── components/    # React components
│   │   └── *.css          # Styling
│   ├── public/
│   ├── package.json       # Frontend dependencies
│   ├── Dockerfile         # Frontend container image
│   └── nginx.conf         # Nginx configuration
└── openshift/
    ├── backend-deployment.yaml
    ├── frontend-deployment.yaml
    ├── routes.yaml
    ├── configmap.yaml
    ├── secrets.yaml.template
    ├── backend-buildconfig.yaml
    └── frontend-buildconfig.yaml
```

## Setup Instructions

### Step 1: Get Stripe API Keys

1. Log in to your [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to **Developers** → **API keys**
3. Copy your:
   - **Publishable key** (starts with `pk_test_` for test mode)
   - **Secret key** (starts with `sk_test_` for test mode)

### Step 2: Configure Secrets

1. Copy the secrets template:
   ```bash
   cp openshift/secrets.yaml.template openshift/secrets.yaml
   ```

2. Edit `openshift/secrets.yaml` and add your Stripe keys:
   ```yaml
   stringData:
     stripe-secret-key: "sk_test_your_actual_secret_key"
     stripe-publishable-key: "pk_test_your_actual_publishable_key"
     stripe-webhook-secret: "whsec_your_webhook_secret"  # Optional for now
   ```

3. **Important**: Add `secrets.yaml` to `.gitignore` to prevent committing secrets

### Step 3: Login to OpenShift

```bash
# Login to your OpenShift cluster
oc login --token=<your-token> --server=<your-server-url>

# Create a new project
oc new-project stripe-payment-app
```

### Step 4: Update Configuration

Edit `openshift/configmap.yaml` with your actual OpenShift route URLs:

```yaml
data:
  api-url: "https://api-stripe-payment.apps.your-cluster.example.com"
  frontend-url: "https://stripe-payment.apps.your-cluster.example.com"
```

Edit `openshift/routes.yaml` with your desired hostnames:

```yaml
spec:
  host: stripe-payment.apps.your-cluster.example.com  # Frontend
---
spec:
  host: api-stripe-payment.apps.your-cluster.example.com  # Backend
```

### Step 5: Deploy to OpenShift

#### Option A: Using Pre-built Images (Recommended for testing)

1. **Build Docker images locally**:
   ```bash
   # Build backend
   cd backend
   docker build -t stripe-backend:latest .
   
   # Build frontend
   cd ../frontend
   docker build -t stripe-frontend:latest .
   ```

2. **Push to OpenShift internal registry**:
   ```bash
   # Get registry URL
   REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
   
   # Login to registry
   docker login -u $(oc whoami) -p $(oc whoami -t) $REGISTRY
   
   # Tag and push images
   docker tag stripe-backend:latest $REGISTRY/stripe-payment-app/stripe-backend:latest
   docker tag stripe-frontend:latest $REGISTRY/stripe-payment-app/stripe-frontend:latest
   
   docker push $REGISTRY/stripe-payment-app/stripe-backend:latest
   docker push $REGISTRY/stripe-payment-app/stripe-frontend:latest
   ```

3. **Update deployment manifests** to use your registry:
   ```yaml
   # In backend-deployment.yaml and frontend-deployment.yaml
   image: image-registry.openshift-image-registry.svc:5000/stripe-payment-app/stripe-backend:latest
   ```

4. **Deploy all resources**:
   ```bash
   cd openshift
   
   # Create secrets
   oc apply -f secrets.yaml
   
   # Create configmap
   oc apply -f configmap.yaml
   
   # Deploy backend
   oc apply -f backend-deployment.yaml
   
   # Deploy frontend
   oc apply -f frontend-deployment.yaml
   
   # Create routes
   oc apply -f routes.yaml
   ```

#### Option B: Using OpenShift Source-to-Image (S2I)

1. **Push code to Git repository**

2. **Update BuildConfigs** with your Git repository URL:
   ```yaml
   # In backend-buildconfig.yaml and frontend-buildconfig.yaml
   git:
     uri: https://github.com/your-org/your-repo.git
   ```

3. **Deploy**:
   ```bash
   cd openshift
   
   # Create secrets and config
   oc apply -f secrets.yaml
   oc apply -f configmap.yaml
   
   # Create build configurations
   oc apply -f backend-buildconfig.yaml
   oc apply -f frontend-buildconfig.yaml
   
   # Start builds
   oc start-build stripe-backend-build
   oc start-build stripe-frontend-build
   
   # Wait for builds to complete
   oc logs -f bc/stripe-backend-build
   oc logs -f bc/stripe-frontend-build
   
   # Deploy applications
   oc apply -f backend-deployment.yaml
   oc apply -f frontend-deployment.yaml
   oc apply -f routes.yaml
   ```

### Step 6: Verify Deployment

```bash
# Check pod status
oc get pods

# Check services
oc get svc

# Check routes
oc get routes

# View logs
oc logs -f deployment/stripe-backend
oc logs -f deployment/stripe-frontend
```

### Step 7: Access the Application

Get the frontend URL:
```bash
oc get route stripe-frontend-route -o jsonpath='{.spec.host}'
```

Open the URL in your browser: `https://stripe-payment.apps.your-cluster.example.com`

## Testing Payments

The application is configured for Stripe test mode. Use these test card numbers:

- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **3D Secure**: `4000 0027 6000 3184`

Use any:
- Future expiration date
- Any 3-digit CVC
- Any billing ZIP code

## Monitoring

```bash
# View backend logs
oc logs -f deployment/stripe-backend

# View frontend logs
oc logs -f deployment/stripe-frontend

# Check resource usage
oc adm top pods

# Describe deployments
oc describe deployment stripe-backend
oc describe deployment stripe-frontend
```

## Scaling

```bash
# Scale backend
oc scale deployment/stripe-backend --replicas=3

# Scale frontend
oc scale deployment/stripe-frontend --replicas=3
```

## Configure Webhooks (Optional)

1. Get your backend route URL:
   ```bash
   oc get route stripe-backend-route -o jsonpath='{.spec.host}'
   ```

2. In Stripe Dashboard, go to **Developers** → **Webhooks**

3. Add endpoint: `https://api-your-domain.apps.openshift.example.com/api/webhook`

4. Select events to listen for (e.g., `payment_intent.succeeded`, `payment_intent.payment_failed`)

5. Copy the webhook signing secret

6. Update the secret:
   ```bash
   oc patch secret stripe-secrets --type='json' -p='[{"op": "replace", "path": "/data/stripe-webhook-secret", "value":"'$(echo -n "whsec_your_webhook_secret" | base64)'"}]'
   ```

7. Restart backend pods:
   ```bash
   oc rollout restart deployment/stripe-backend
   ```

## Troubleshooting

### Pods not starting
```bash
# Check events
oc get events --sort-by='.lastTimestamp'

# Check pod details
oc describe pod <pod-name>

# Check logs
oc logs <pod-name>
```

### Cannot pull images
```bash
# Verify image stream
oc get imagestream

# Check build logs
oc logs bc/<buildconfig-name>
```

### Route not accessible
```bash
# Check route configuration
oc describe route stripe-frontend-route

# Verify service endpoints
oc get endpoints
```

### Backend cannot connect to Stripe
```bash
# Verify secrets are set
oc get secret stripe-secrets -o yaml

# Check environment variables in pod
oc exec deployment/stripe-backend -- env | grep STRIPE
```

## Security Best Practices

1. **Never commit secrets** - Use OpenShift secrets for sensitive data
2. **Use HTTPS** - Routes are configured with TLS termination
3. **Non-root containers** - Images run as non-root user (UID 1001)
4. **Resource limits** - Set appropriate CPU and memory limits
5. **Network policies** - Consider implementing network policies for production
6. **Image scanning** - Scan container images for vulnerabilities
7. **RBAC** - Use role-based access control for OpenShift resources

## Production Considerations

Before going to production:

1. **Switch to live Stripe keys** (starts with `sk_live_` and `pk_live_`)
2. **Configure proper domain names** with SSL certificates
3. **Set up monitoring and alerting**
4. **Implement backup strategy**
5. **Configure autoscaling**:
   ```bash
   oc autoscale deployment/stripe-backend --min=2 --max=10 --cpu-percent=70
   ```
6. **Set resource quotas and limits**
7. **Implement proper logging aggregation**
8. **Configure database** for persistent data (not included in this example)
9. **Set up CI/CD pipeline**

## Environment Variables Reference

### Backend
- `PORT`: Server port (default: 8080)
- `NODE_ENV`: Environment (production/development)
- `STRIPE_SECRET_KEY`: Stripe secret API key
- `STRIPE_PUBLISHABLE_KEY`: Stripe publishable key
- `STRIPE_WEBHOOK_SECRET`: Stripe webhook signing secret
- `FRONTEND_URL`: Frontend URL for CORS

### Frontend
- `REACT_APP_API_URL`: Backend API URL

## Clean Up

To remove all resources:

```bash
# Delete all resources
oc delete all -l app=stripe-payment

# Delete secrets and configmaps
oc delete secret stripe-secrets
oc delete configmap app-config

# Delete project
oc delete project stripe-payment-app
```

## Support

For issues:
- **Stripe**: https://support.stripe.com
- **OpenShift**: https://docs.openshift.com

## License

MIT License - Feel free to use and modify for your needs.
