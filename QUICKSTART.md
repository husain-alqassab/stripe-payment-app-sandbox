# Quick Start Guide

This guide helps you get the Stripe payment application running quickly.

## Local Development (Without OpenShift)

### Prerequisites
- Node.js 18+ installed
- Stripe account (https://stripe.com)

### Steps

1. **Clone/Download the project**

2. **Get Stripe API keys**
   - Go to https://dashboard.stripe.com/test/apikeys
   - Copy your test keys

3. **Setup Backend**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Edit .env and add your Stripe keys
   npm start
   ```
   Backend runs on http://localhost:8080

4. **Setup Frontend** (in a new terminal)
   ```bash
   cd frontend
   npm install
   cp .env.example .env
   # Edit .env if needed (default should work)
   npm start
   ```
   Frontend runs on http://localhost:3000

5. **Test the application**
   - Open http://localhost:3000
   - Select a plan
   - Use test card: 4242 4242 4242 4242
   - Any future date, any CVC, any ZIP

## Docker Compose (Local Testing)

```bash
# Set your Stripe keys
export STRIPE_SECRET_KEY=sk_test_your_key
export STRIPE_PUBLISHABLE_KEY=pk_test_your_key

# Start services
docker-compose up --build

# Access application
# Frontend: http://localhost:3000
# Backend: http://localhost:8080
```

## OpenShift Deployment

See the main [README.md](README.md) for detailed OpenShift deployment instructions.

### Quick OpenShift Deploy

```bash
# Login to OpenShift
oc login --token=<your-token> --server=<your-server>

# Create project
oc new-project stripe-payment-app

# Update secrets
cp openshift/secrets.yaml.template openshift/secrets.yaml
# Edit secrets.yaml with your Stripe keys

# Deploy everything
cd openshift
oc apply -f secrets.yaml
oc apply -f configmap.yaml
oc apply -f backend-deployment.yaml
oc apply -f frontend-deployment.yaml
oc apply -f routes.yaml

# Get URL
oc get route stripe-frontend-route
```

## Test Cards

- **Success**: 4242 4242 4242 4242
- **Decline**: 4000 0000 0000 0002
- **Requires Authentication**: 4000 0027 6000 3184

Use any future expiration date, any 3-digit CVC, and any ZIP code.

## Troubleshooting

**Backend won't start**
- Check if port 8080 is available
- Verify Stripe keys in .env file
- Check logs: `npm start` shows errors

**Frontend won't start**
- Check if port 3000 is available
- Verify backend is running
- Check REACT_APP_API_URL in .env

**Payment fails**
- Verify you're using test mode keys (start with sk_test_ and pk_test_)
- Check browser console for errors
- Verify backend logs for Stripe API errors

## Next Steps

1. Review the main [README.md](README.md) for production deployment
2. Customize products in `backend/server.js`
3. Update styling in frontend CSS files
4. Set up webhooks for production
5. Add database for order tracking

## Support

- Stripe Documentation: https://stripe.com/docs
- OpenShift Documentation: https://docs.openshift.com
