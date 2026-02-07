# How to Upload Your Stripe Payment App to GitHub

This guide will walk you through uploading your application to GitHub step by step.

## Method 1: Using GitHub Web Interface (Easiest for Beginners)

### Step 1: Create a GitHub Account
1. Go to https://github.com
2. Click "Sign up" if you don't have an account
3. Follow the registration process

### Step 2: Create a New Repository
1. Click the "+" icon in the top-right corner
2. Select "New repository"
3. Fill in the details:
   - **Repository name**: `stripe-payment-app` (or your preferred name)
   - **Description**: "Customer-facing payment application with Stripe integration for OpenShift"
   - **Visibility**: Choose "Private" (recommended for apps with secrets) or "Public"
   - **DO NOT** check "Initialize this repository with a README" (we already have one)
4. Click "Create repository"

### Step 3: Upload Files via Web Interface
1. On your new repository page, click "uploading an existing file"
2. Extract the `stripe-payment-app.tar.gz` file on your computer
3. Drag and drop ALL folders and files from the extracted directory
4. **IMPORTANT**: Make sure you DO NOT upload `openshift/secrets.yaml` (it should be ignored by .gitignore)
5. Add a commit message: "Initial commit: Stripe payment application"
6. Click "Commit changes"

### Important Notes:
- Never upload files containing real Stripe API keys
- The `.gitignore` file will prevent secrets from being uploaded
- Always use the `secrets.yaml.template` for sharing

---

## Method 2: Using Git Command Line (Recommended)

### Prerequisites
- Git installed on your computer
- Download from: https://git-scm.com/downloads

### Step 1: Extract the Archive
```bash
# Extract the application
tar -xzf stripe-payment-app.tar.gz
cd stripe-payment-app
```

### Step 2: Initialize Git Repository
```bash
# Initialize git
git init

# Check that .gitignore exists (it should prevent secrets.yaml from being committed)
cat .gitignore
```

### Step 3: Create GitHub Repository
1. Go to https://github.com/new
2. Create a new repository (as described in Method 1, Step 2)
3. **DO NOT** initialize with README, .gitignore, or license

### Step 4: Link and Push to GitHub
After creating the repository, GitHub will show you commands. Use these:

```bash
# Add all files (secrets.yaml will be ignored by .gitignore)
git add .

# Check what will be committed (secrets.yaml should NOT appear here)
git status

# If you see secrets.yaml in the list, remove it:
git rm --cached openshift/secrets.yaml

# Commit your files
git commit -m "Initial commit: Stripe payment application"

# Add your GitHub repository as remote
# Replace YOUR_USERNAME and YOUR_REPO with your actual values
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 5: Verify Upload
1. Go to your GitHub repository URL
2. Verify all files are there
3. **CRITICAL CHECK**: Make sure `openshift/secrets.yaml` is NOT visible
4. You should see `openshift/secrets.yaml.template` instead

---

## Method 3: Using GitHub Desktop (User-Friendly GUI)

### Step 1: Install GitHub Desktop
1. Download from: https://desktop.github.com
2. Install and sign in with your GitHub account

### Step 2: Create Repository
1. Click "File" → "New repository"
2. Name: `stripe-payment-app`
3. Local path: Choose where you extracted the files
4. Click "Create repository"

### Step 3: Add Files
1. Extract `stripe-payment-app.tar.gz` to your chosen location
2. GitHub Desktop will automatically detect all files
3. Review the files in the "Changes" tab
4. **VERIFY**: `openshift/secrets.yaml` should NOT appear (thanks to .gitignore)

### Step 4: Commit and Push
1. Add commit message: "Initial commit: Stripe payment application"
2. Click "Commit to main"
3. Click "Publish repository"
4. Choose visibility (Private recommended)
5. Click "Publish repository"

---

## Security Checklist Before Uploading

### ✅ MUST DO Before Pushing to GitHub:

1. **Check .gitignore exists** and contains:
   ```
   .env
   .env.local
   openshift/secrets.yaml
   ```

2. **Verify no secrets in code**:
   ```bash
   # Search for potential secrets
   grep -r "sk_live_" .
   grep -r "sk_test_" .
   grep -r "pk_live_" .
   
   # Should return no results in committed files
   ```

3. **Use template files**:
   - ✅ Commit: `secrets.yaml.template`
   - ❌ Never commit: `secrets.yaml`
   - ✅ Commit: `.env.example`
   - ❌ Never commit: `.env`

4. **Double-check before first push**:
   ```bash
   # See what will be committed
   git status
   
   # If secrets.yaml appears, remove it:
   git rm --cached openshift/secrets.yaml
   echo "openshift/secrets.yaml" >> .gitignore
   git add .gitignore
   git commit -m "Update .gitignore to exclude secrets"
   ```

---

## After Uploading to GitHub

### Update Your Deployment Script
If using the automated deployment script, update the BuildConfigs to use your GitHub repository:

1. Edit `deploy-openshift.sh`
2. Or manually update `openshift/backend-buildconfig.yaml` and `openshift/frontend-buildconfig.yaml`:

```yaml
spec:
  source:
    type: Git
    git:
      uri: https://github.com/YOUR_USERNAME/stripe-payment-app.git
      ref: main
```

### Configure OpenShift to Use Your Repository

When deploying to OpenShift:

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/stripe-payment-app.git
cd stripe-payment-app

# Create secrets file (not in git)
cp openshift/secrets.yaml.template openshift/secrets.yaml

# Edit with your actual Stripe keys
nano openshift/secrets.yaml

# Run deployment
./deploy-openshift.sh
```

---

## Managing Secrets Securely

### Option 1: Environment Variables (Recommended for Teams)
Never commit secrets. Instead, team members should:

1. Get Stripe keys from team's password manager
2. Create `openshift/secrets.yaml` locally
3. Deploy using their own secrets

### Option 2: GitHub Secrets (for CI/CD)
If using GitHub Actions:

1. Go to repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `STRIPE_SECRET_KEY`
   - `STRIPE_PUBLISHABLE_KEY`
3. Reference in workflows (not included in this template)

### Option 3: Encrypted Secrets (Advanced)
Use tools like:
- **git-crypt**: Encrypt secrets in repository
- **SOPS**: Encrypted secret files
- **Sealed Secrets**: For Kubernetes/OpenShift

---

## Common Issues and Solutions

### Issue: Accidentally Committed Secrets

**IMMEDIATE ACTION REQUIRED:**

1. **Revoke the exposed keys** in Stripe Dashboard immediately
2. **Remove from Git history**:
   ```bash
   # Install BFG Repo-Cleaner
   # Download from: https://rtyley.github.io/bfg-repo-cleaner/
   
   # Remove secrets.yaml from history
   bfg --delete-files secrets.yaml
   
   # Clean up
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   
   # Force push (WARNING: Rewrites history)
   git push --force
   ```

3. **Generate new Stripe keys**
4. **Update your application** with new keys

### Issue: Files Too Large

GitHub has file size limits (100MB per file, 1GB repository):

```bash
# Check large files
find . -type f -size +50M

# Use Git LFS for large files if needed
git lfs install
git lfs track "*.large"
```

### Issue: Push Rejected

```bash
# If branch is behind remote
git pull origin main --rebase
git push origin main

# If force push needed (use carefully)
git push origin main --force
```

---

## Sharing Your Repository

### Making it Public
1. Go to repository Settings
2. Scroll to "Danger Zone"
3. Click "Change visibility"
4. Select "Make public"
5. Confirm

### Adding Collaborators (Private Repo)
1. Go to repository Settings
2. Click "Collaborators"
3. Click "Add people"
4. Enter GitHub username or email
5. Set permissions (Read, Write, or Admin)

### Adding a README Badge
Add this to your README.md:

```markdown
![OpenShift](https://img.shields.io/badge/OpenShift-Ready-red)
![Stripe](https://img.shields.io/badge/Stripe-Integrated-blue)
![License](https://img.shields.io/badge/license-MIT-green)
```

---

## Best Practices

1. ✅ **Always use .gitignore** for secrets
2. ✅ **Use template files** for configuration examples
3. ✅ **Document environment variables** needed
4. ✅ **Write clear commit messages**
5. ✅ **Keep secrets out of code** - use environment variables
6. ✅ **Review changes** before committing
7. ✅ **Use branches** for new features
8. ✅ **Tag releases** for version control

### Good Commit Messages:
- ✅ "Add Stripe webhook handling"
- ✅ "Fix payment confirmation UI"
- ✅ "Update OpenShift deployment config"
- ❌ "changes"
- ❌ "fixed stuff"
- ❌ "asdf"

---

## Next Steps After Upload

1. **Verify deployment** from GitHub:
   ```bash
   git clone https://github.com/YOUR_USERNAME/stripe-payment-app.git
   cd stripe-payment-app
   ./deploy-openshift.sh
   ```

2. **Set up CI/CD** (Optional but recommended):
   - GitHub Actions for automated testing
   - OpenShift pipelines for automated deployment

3. **Add documentation**:
   - API documentation
   - Architecture diagrams
   - Contributing guidelines

4. **Consider adding**:
   - Issue templates
   - Pull request templates
   - Code of conduct
   - License file (MIT recommended)

---

## Getting Help

- **GitHub Docs**: https://docs.github.com
- **Git Docs**: https://git-scm.com/doc
- **GitHub Community**: https://github.community

---

## Quick Reference Commands

```bash
# Clone repository
git clone https://github.com/USERNAME/REPO.git

# Check status
git status

# Add files
git add .

# Commit changes
git commit -m "Your message"

# Push to GitHub
git push origin main

# Pull latest changes
git pull origin main

# Create new branch
git checkout -b feature-name

# Switch branches
git checkout main

# View commit history
git log --oneline
```

---

**Remember**: Never commit actual Stripe API keys, always use test keys for development, and keep production keys secure in environment variables or secret management systems.
