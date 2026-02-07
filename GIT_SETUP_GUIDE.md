# Git Setup and Upload Guide

This guide walks you through uploading the Stripe Payment Application to a Git repository (GitHub, GitLab, or Bitbucket).

## Prerequisites

- Git installed on your computer ([Download Git](https://git-scm.com/downloads))
- A GitHub, GitLab, or Bitbucket account
- Terminal/Command Prompt access

## Option 1: Using GitHub (Recommended)

### Step 1: Create a New Repository on GitHub

1. **Go to GitHub**: https://github.com
2. **Sign in** to your account
3. **Click** the `+` icon in the top right corner
4. **Select** "New repository"
5. **Fill in the details**:
   - Repository name: `stripe-payment-app` (or your preferred name)
   - Description: "Customer-facing payment application with Stripe integration"
   - Visibility: Choose **Private** (recommended for security)
   - **DO NOT** check "Initialize this repository with a README"
6. **Click** "Create repository"

### Step 2: Prepare Your Local Files

1. **Extract the application** (if you haven't already):
   ```bash
   tar -xzf stripe-payment-app.tar.gz
   cd stripe-payment-app
   ```

2. **Initialize Git repository**:
   ```bash
   git init
   ```

3. **Configure your Git identity** (if not already done):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

### Step 3: Configure Secrets (IMPORTANT!)

Before uploading, ensure your secrets are protected:

1. **Verify .gitignore exists**:
   ```bash
   cat .gitignore
   ```
   
   It should include:
   ```
   .env
   .env.local
   openshift/secrets.yaml
   ```

2. **Create secrets.yaml from template** (do this AFTER pushing to Git):
   ```bash
   # Don't do this yet - do it after uploading to Git
   # cp openshift/secrets.yaml.template openshift/secrets.yaml
   ```

### Step 4: Add and Commit Files

1. **Add all files to Git**:
   ```bash
   git add .
   ```

2. **Verify what will be committed** (secrets.yaml should NOT appear):
   ```bash
   git status
   ```
   
   You should see files like:
   - backend/
   - frontend/
   - openshift/
   - README.md
   - etc.
   
   You should **NOT** see:
   - openshift/secrets.yaml (only secrets.yaml.template should be there)
   - .env files
   
3. **Commit the files**:
   ```bash
   git commit -m "Initial commit: Stripe payment application with