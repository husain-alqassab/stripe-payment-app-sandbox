# GitHub Upload - Quick Checklist

## ⚡ Fast Track (5 Minutes)

### Before You Start
- [ ] Extract `stripe-payment-app.tar.gz` to your computer
- [ ] Have GitHub account ready (create at github.com if needed)

---

## 🌐 Method 1: Web Upload (Easiest)

### Step 1: Create Repository (2 min)
1. [ ] Go to https://github.com/new
2. [ ] Repository name: `stripe-payment-app`
3. [ ] Select Private or Public
4. [ ] Click "Create repository"

### Step 2: Upload Files (2 min)
1. [ ] Click "uploading an existing file"
2. [ ] Drag all folders/files from extracted directory
3. [ ] **SKIP** `openshift/secrets.yaml` if it exists
4. [ ] Commit message: "Initial commit"
5. [ ] Click "Commit changes"

### Step 3: Verify (1 min)
- [ ] Check all files are visible on GitHub
- [ ] Verify `secrets.yaml.template` exists
- [ ] Verify `secrets.yaml` is NOT there
- [ ] Done! ✅

---

## 💻 Method 2: Command Line (Recommended)

### Step 1: Extract & Prepare
```bash
tar -xzf stripe-payment-app.tar.gz
cd stripe-payment-app
```

### Step 2: Create GitHub Repo
- [ ] Go to https://github.com/new
- [ ] Create repository (don't initialize)
- [ ] Copy the repository URL

### Step 3: Upload
```bash
# Initialize git
git init

# Add files
git add .

# Check status (secrets.yaml should NOT appear)
git status

# Commit
git commit -m "Initial commit: Stripe payment application"

# Replace with your actual repository URL
git remote add origin https://github.com/YOUR_USERNAME/stripe-payment-app.git

# Push
git branch -M main
git push -u origin main
```

### Step 4: Verify
- [ ] Visit your GitHub repository
- [ ] Verify all files uploaded
- [ ] Done! ✅

---

## 🔒 Security Checklist (IMPORTANT!)

Before pushing to GitHub, verify:

- [ ] `.gitignore` file exists
- [ ] `secrets.yaml.template` exists (this is OK to commit)
- [ ] `secrets.yaml` does NOT exist in git (run `git status` to check)
- [ ] No Stripe keys in any code files
- [ ] `.env.example` files exist (OK to commit)
- [ ] `.env` files are NOT committed

---

## ⚠️ If You Accidentally Committed Secrets

**STOP AND DO THIS IMMEDIATELY:**

1. **Revoke the keys in Stripe Dashboard**: https://dashboard.stripe.com/apikeys
2. **Delete the repository** from GitHub
3. **Create a new repository** 
4. **Ensure .gitignore includes secrets.yaml** before pushing again
5. **Generate new Stripe keys**

---

## 📝 What Gets Uploaded

✅ **Should be in GitHub:**
- All source code (frontend/backend)
- Dockerfile files
- OpenShift configuration files
- README files
- `.gitignore`
- `secrets.yaml.template`
- `.env.example`

❌ **Should NOT be in GitHub:**
- `secrets.yaml`
- `.env`
- `node_modules/`
- Any files with actual API keys

---

## 🚀 After Upload

### To deploy from GitHub:

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/stripe-payment-app.git
cd stripe-payment-app

# Create secrets (not in git)
cp openshift/secrets.yaml.template openshift/secrets.yaml

# Edit with your Stripe keys
nano openshift/secrets.yaml

# Deploy to OpenShift
./deploy-openshift.sh
```

---

## 🆘 Need Help?

**Can't push to GitHub?**
```bash
# Make sure you're logged in
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# Try again
git push origin main
```

**Files too large?**
- GitHub has 100MB per file limit
- Check large files: `find . -type f -size +50M`

**Already have a main branch?**
```bash
git pull origin main --rebase
git push origin main
```

---

## ✅ Success Indicators

You've successfully uploaded when:

1. ✅ You can see your code at `https://github.com/YOUR_USERNAME/stripe-payment-app`
2. ✅ All folders (frontend, backend, openshift) are visible
3. ✅ README.md displays on the main page
4. ✅ `secrets.yaml` is NOT visible
5. ✅ `secrets.yaml.template` IS visible

---

**Next Step**: See QUICKSTART.md for deployment instructions
