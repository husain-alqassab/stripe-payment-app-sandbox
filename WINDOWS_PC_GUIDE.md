# GitHub Upload Guide for Windows PC

## 🖥️ Easy Steps for Windows Users

### What You'll Need
- Windows PC (you have this ✓)
- The downloaded `stripe-payment-app.tar.gz` file
- Internet connection
- GitHub account (free)

---

## 🌟 EASIEST METHOD: GitHub Desktop (Recommended for Windows)

This is the simplest way - uses a graphical interface, no commands needed!

### Step 1: Install GitHub Desktop (5 minutes)

1. **Download GitHub Desktop**
   - Go to: https://desktop.github.com
   - Click "Download for Windows"
   - Wait for download to complete

2. **Install GitHub Desktop**
   - Double-click the downloaded file
   - Follow the installation wizard
   - Click "Next" → "Install" → "Finish"

3. **Sign in to GitHub**
   - Open GitHub Desktop
   - Click "Sign in to GitHub.com"
   - If you don't have an account:
     - Click "Create your free account"
     - Fill in username, email, password
     - Verify email
   - Sign in with your credentials

### Step 2: Extract Your Application Files (2 minutes)

1. **Extract the .tar.gz file**
   - Locate `stripe-payment-app.tar.gz` in your Downloads folder
   - Right-click on the file
   
   **Option A - Using Windows 11/10:**
   - Right-click → "Extract All"
   - Choose a location (e.g., Documents)
   - Click "Extract"
   
   **Option B - If Extract All doesn't work:**
   - Download 7-Zip from: https://www.7-zip.org
   - Install 7-Zip
   - Right-click file → 7-Zip → "Extract Here"

2. **Note the location**
   - Remember where you extracted it
   - Example: `C:\Users\YourName\Documents\stripe-payment-app`

### Step 3: Create Repository in GitHub Desktop (3 minutes)

1. **Create New Repository**
   - Open GitHub Desktop
   - Click "File" → "Add Local Repository"
   - Click "Choose..." button
   - Navigate to your extracted folder: `stripe-payment-app`
   - Click "Select Folder"
   
2. **If you see "This directory does not appear to be a Git repository":**
   - Click "Create a repository"
   - Repository name: `stripe-payment-app`
   - Keep other settings as default
   - Click "Create Repository"

### Step 4: Check Files (IMPORTANT - 2 minutes)

1. **Review what will be uploaded**
   - In GitHub Desktop, you'll see a list of files on the left
   - Look through the list

2. **SECURITY CHECK - Make sure you DO NOT see:**
   - ❌ `secrets.yaml` (without .template)
   - ❌ `.env` (without .example)
   - ❌ Any file with real Stripe API keys

3. **You SHOULD see:**
   - ✅ `secrets.yaml.template`
   - ✅ `.env.example`
   - ✅ All folders: frontend, backend, openshift
   - ✅ README.md

### Step 5: Upload to GitHub (2 minutes)

1. **Commit your files**
   - At the bottom left, you'll see "Summary (required)"
   - Type: `Initial commit - Stripe payment application`
   - Click the blue "Commit to main" button

2. **Publish to GitHub**
   - Click "Publish repository" button at the top
   - Choose a name (keep `stripe-payment-app`)
   - Add description: "Customer payment app with Stripe for OpenShift"
   - **Choose visibility:**
     - ☑️ Keep this code private (RECOMMENDED - check this box)
     - ⬜ Public (only if you're sure no secrets are included)
   - Click "Publish repository"

3. **Wait for upload**
   - You'll see a progress bar
   - Wait until it says "Published"

### Step 6: Verify on GitHub.com (1 minute)

1. **View on GitHub**
   - In GitHub Desktop, click "Repository" → "View on GitHub"
   - Your browser will open
   - You should see all your files!

2. **Final Security Check:**
   - Browse the files on GitHub.com
   - Click into the `openshift` folder
   - ✅ Verify you see: `secrets.yaml.template`
   - ❌ Verify you DON'T see: `secrets.yaml`

### ✅ SUCCESS! You're Done!

Your application is now on GitHub at:
`https://github.com/YOUR-USERNAME/stripe-payment-app`

---

## 🔧 ALTERNATIVE METHOD: Using Command Line (Git Bash)

If you prefer using commands or GitHub Desktop doesn't work:

### Step 1: Install Git for Windows

1. Download Git from: https://git-scm.com/download/win
2. Run the installer
3. Use default settings (just keep clicking "Next")
4. Finish installation

### Step 2: Extract Files

1. Extract `stripe-payment-app.tar.gz` using 7-Zip or Windows Extract
2. Note the location (e.g., `C:\Users\YourName\Documents\stripe-payment-app`)

### Step 3: Open Git Bash

1. Navigate to the extracted folder in File Explorer
2. Right-click inside the folder
3. Select "Git Bash Here"
4. A black terminal window will open

### Step 4: Run These Commands

Copy and paste each line, press Enter after each:

```bash
# Initialize git
git init

# Add all files
git add .

# Check what will be uploaded (secrets.yaml should NOT appear)
git status

# If you see secrets.yaml in red/green, remove it:
git rm --cached openshift/secrets.yaml

# Commit files
git commit -m "Initial commit: Stripe payment application"
```

### Step 5: Create Repository on GitHub.com

1. Open browser and go to: https://github.com/new
2. Repository name: `stripe-payment-app`
3. Choose Private or Public
4. **DO NOT** check any boxes (README, .gitignore, license)
5. Click "Create repository"
6. **Keep this page open** - you'll need the commands shown

### Step 6: Push to GitHub

Back in Git Bash, copy the commands from GitHub (they look like this):

```bash
# Replace YOUR-USERNAME with your actual GitHub username
git remote add origin https://github.com/YOUR-USERNAME/stripe-payment-app.git
git branch -M main
git push -u origin main
```

When prompted:
- Username: Your GitHub username
- Password: Your GitHub password (or Personal Access Token)

### Step 7: Verify

1. Refresh your GitHub repository page
2. You should see all your files!

---

## 📱 SIMPLEST METHOD: Direct Web Upload (No Installation)

If you don't want to install anything:

### Step 1: Create GitHub Account
1. Go to https://github.com
2. Sign up (free)
3. Verify your email

### Step 2: Extract Files
1. Extract `stripe-payment-app.tar.gz` 
2. You'll have a folder with all the files

### Step 3: Create Repository
1. Go to: https://github.com/new
2. Repository name: `stripe-payment-app`
3. Choose "Private" (recommended)
4. Click "Create repository"

### Step 4: Upload Files
1. Click "uploading an existing file" link
2. Open your extracted folder in File Explorer
3. **Select all folders and files** (Ctrl+A)
4. **Drag and drop** into the GitHub page
5. Wait for upload (may take 1-2 minutes)
6. Scroll down
7. Click "Commit changes"

### Step 5: Verify
1. Check all files are visible
2. Look in `openshift` folder
3. Verify NO `secrets.yaml` file (only `secrets.yaml.template`)

---

## ⚠️ IMPORTANT: Before Uploading - Security Check

### Open these files in Notepad and verify NO real API keys:

1. **Check backend/.env** (if it exists)
   - Should NOT exist, or should have fake/example values
   
2. **Check openshift/secrets.yaml** (if it exists)
   - Should NOT be uploaded
   - Only `secrets.yaml.template` should be uploaded

3. **Look for these patterns** - they should NOT be in your code:
   - `sk_live_` (Stripe live secret key)
   - `sk_test_` followed by real values
   - Real API keys or passwords

### How to check:
1. Open File Explorer
2. Go to your extracted folder
3. In the search box, type: `sk_live_`
4. If any files appear, open them and remove the keys
5. Search for: `sk_test_`
6. Make sure these only appear in `.example` files

---

## 🆘 Troubleshooting

### Problem: Can't extract .tar.gz file

**Solution:**
1. Download 7-Zip: https://www.7-zip.org
2. Install it
3. Right-click the file → 7-Zip → Extract Here

### Problem: GitHub Desktop won't install

**Solution:**
- Use the Web Upload method instead (no installation needed)
- Or use Git Bash (Command Line method)

### Problem: Upload is very slow

**Solution:**
- Your internet might be slow
- Try the Command Line method (can resume if interrupted)
- Or upload in parts (upload backend, then frontend, then openshift)

### Problem: "Repository already exists"

**Solution:**
- Choose a different name
- Or delete the existing repository:
  - Go to repository Settings
  - Scroll to bottom
  - Click "Delete this repository"

### Problem: Asking for password but password doesn't work

**Solution:**
GitHub now requires Personal Access Token instead of password:
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name: "stripe-app-upload"
4. Check "repo" scope
5. Click "Generate token"
6. Copy the token (save it somewhere safe!)
7. Use this token as your password

---

## ✅ What Success Looks Like

After uploading, you should be able to:

1. ✅ Visit `https://github.com/YOUR-USERNAME/stripe-payment-app`
2. ✅ See all your folders: `backend`, `frontend`, `openshift`
3. ✅ Click on files and view their contents
4. ✅ See `README.md` displayed on the main page
5. ✅ See `secrets.yaml.template` in openshift folder
6. ✅ NOT see `secrets.yaml` anywhere

---

## 🚀 Next Steps (After Upload)

Now that your code is on GitHub, you can deploy it to OpenShift!

### To deploy:

1. **Get your GitHub repository URL**
   - Example: `https://github.com/YOUR-USERNAME/stripe-payment-app.git`

2. **Follow the deployment guide** in README.md

3. **When OpenShift asks for Git URL**, provide your GitHub repository URL

---

## 💡 Pro Tips

1. **Private vs Public Repository:**
   - Choose PRIVATE if you're not sure
   - You can always make it public later
   - Private repos keep your code hidden from others

2. **Save Your Work Frequently:**
   - After making changes, commit and push regularly
   - In GitHub Desktop: just click "Commit" and "Push"

3. **Collaborate with Others:**
   - Add team members in repository Settings → Collaborators
   - They can clone and work on the code too

4. **Make Changes Later:**
   - Edit files locally
   - Commit changes in GitHub Desktop
   - Click "Push origin" to upload changes

---

## 📞 Need More Help?

- **GitHub Support:** https://support.github.com
- **Video Tutorial:** Search YouTube for "How to upload to GitHub"
- **GitHub Desktop Docs:** https://docs.github.com/en/desktop

---

**Remember:** Your first upload is the hardest. After this, it gets much easier! 🎉
