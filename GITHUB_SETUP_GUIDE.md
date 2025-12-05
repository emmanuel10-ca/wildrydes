# GitHub Repository Setup Guide

Complete step-by-step guide to create a GitHub repository and generate a personal access token for Wild Rydes deployment.

---

## Step 1: Create a GitHub Repository

### Option A: Using GitHub Web Interface

1. **Go to GitHub**
   - Open https://github.com
   - Sign in with your GitHub account
   - If you don't have an account, create one at https://github.com/signup

2. **Create New Repository**
   - Click the `+` icon in the top-right corner
   - Select "New repository"
   - Or go directly to https://github.com/new

3. **Repository Settings**
   - **Repository name**: `wildrydes` (or your preferred name)
   - **Description**: "Wild Rydes Infrastructure as Code Solution"
   - **Visibility**: 
     - Public (recommended for learning)
     - Or Private (if you prefer)
   - **Initialize repository**:
     - ✓ Check "Add a README file"
     - ✓ Check "Add .gitignore"
     - Select ".gitignore template": Node
   - Click **Create repository**

4. **Copy Repository URL**
   - Click the green **Code** button
   - Copy the HTTPS URL
   - Example: `https://github.com/your-username/wildrydes`

---

## Step 2: Clone the Repository Locally

```bash
# Navigate to desired location
cd c:\Users\HP\Downloads

# Clone the repository
git clone https://github.com/your-username/wildrydes

# Navigate to repository
cd wildrydes
```

---

## Step 3: Copy Wild Rydes Files to Repository

```bash
# Copy all files from the solution to your repository
# Option 1: Manual copy using PowerShell
Copy-Item "C:\Users\HP\Downloads\Azodo_Final Test Practical\*" -Destination "C:\Users\HP\Downloads\wildrydes\" -Exclude ".git" -Force -Recurse

# Option 2: Using Git Bash
cp -r "/c/Users/HP/Downloads/Azodo_Final Test Practical/"* "/c/Users/HP/Downloads/wildrydes/" --exclude=".git"
```

---

## Step 4: Commit and Push Files

```bash
# Navigate to your repository
cd c:\Users\HP\Downloads\wildrydes

# Check Git status
git status

# Add all files
git add .

# Commit files
git commit -m "Initial commit: Wild Rydes Infrastructure as Code"

# Push to GitHub
git push origin main
```

---

## Step 5: Generate GitHub Personal Access Token

### Creating Personal Access Token (Classic)

1. **Go to GitHub Settings**
   - Click your profile picture (top-right corner)
   - Select "Settings"
   - Or go to: https://github.com/settings/profile

2. **Navigate to Developer Settings**
   - On the left sidebar, click "Developer settings" (at the bottom)
   - Or go directly to: https://github.com/settings/apps

3. **Select Personal Access Tokens**
   - Click "Personal access tokens"
   - Select "Tokens (classic)"
   - Or go directly to: https://github.com/settings/tokens

4. **Generate New Token**
   - Click "Generate new token" button
   - Select "Generate new token (classic)"

5. **Configure Token**
   - **Token name**: `wildrydes-deployment` (or your preference)
   - **Expiration**: 
     - Select desired duration (90 days recommended)
     - Or "No expiration" (less secure but more convenient)
   - **Scopes**: Select the following checkboxes:
     - ✓ `repo` (Full control of private repositories)
       - This includes: repo:status, repo_deployment, public_repo, repo:invite
     - ✓ `admin:repo_hook` (Full control of repository hooks)
       - This allows CodePipeline to create webhooks

6. **Review and Create**
   - Scroll down to see selected scopes
   - Click "Generate token" button

7. **Copy the Token**
   - **IMPORTANT**: Copy the token immediately!
   - You will NOT be able to see it again
   - Store it securely (password manager recommended)
   - Example token format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## Step 6: Verify Repository Contents

After pushing files, verify on GitHub:

```bash
# Check remote URL
git remote -v

# Expected output:
# origin  https://github.com/your-username/wildrydes (fetch)
# origin  https://github.com/your-username/wildrydes (push)
```

**On GitHub website**:
- Navigate to your repository
- Verify all files are present:
  - ✓ cloudformation-template.yaml
  - ✓ app.js
  - ✓ package.json
  - ✓ Dockerfile
  - ✓ buildspec.yml
  - ✓ All documentation files
  - ✓ .gitignore
  - ✓ .dockerignore

---

## Step 7: Prepare Deployment Information

Collect the following information for deployment:

**GitHub Repository URL**:
```
https://github.com/your-username/wildrydes
```

**GitHub Personal Access Token**:
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**GitHub Branch**:
```
main
```

---

## Troubleshooting

### Git Clone Fails
**Error**: `fatal: unable to access 'https://github.com/...': Could not resolve host`

**Solution**:
- Check internet connection
- Verify GitHub is not blocked by firewall
- Try using SSH instead:
  ```bash
  ssh-keygen -t ed25519 -C "your-email@example.com"
  # Add public key to GitHub SSH keys
  git clone git@github.com:your-username/wildrydes.git
  ```

### Files Don't Show in Repository
**Solution**:
- Verify files were committed: `git status`
- Verify push succeeded: `git log --oneline`
- Refresh GitHub page in browser
- Check you're on the correct branch

### Can't Generate Token
**Solution**:
- Verify you're logged into GitHub
- Check if you have permission to create tokens
- Try incognito/private browser window
- Clear browser cache

### Token Not Working
**Solution**:
- Verify token hasn't expired
- Check token has correct scopes (repo, admin:repo_hook)
- Regenerate if necessary
- Ensure token is copied correctly (no extra spaces)

---

## Quick Reference

### Git Commands Used
```bash
git clone <repo-url>              # Clone repository
git add .                         # Stage all files
git commit -m "message"           # Commit changes
git push origin main              # Push to GitHub
git status                        # Check status
git log --oneline                 # View commit history
```

### Important URLs
- GitHub: https://github.com
- Your Repository: https://github.com/your-username/wildrydes
- Personal Tokens: https://github.com/settings/tokens
- Account Settings: https://github.com/settings/profile

### Token Scopes Needed
- `repo`: Full control of repositories
- `admin:repo_hook`: Manage repository webhooks

---

## Next Steps After Setup

1. ✅ Repository created on GitHub
2. ✅ All Wild Rydes files pushed to repository
3. ✅ Personal access token generated
4. ➡️ **Next**: Run deployment script with GitHub URL and token

---

## Deployment Command

Once repository is ready, deploy with:

**PowerShell**:
```powershell
.\deploy.ps1 -StackName wildrydes-stack `
            -EnvironmentName wildrydes `
            -GitHubRepo "https://github.com/your-username/wildrydes" `
            -GitHubBranch "main" `
            -GitHubToken "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Bash**:
```bash
./deploy.sh wildrydes-stack wildrydes \
  "https://github.com/your-username/wildrydes" \
  "main" \
  "cloudformation-template.yaml" \
  "us-east-1"
```

---

## Security Notes

⚠️ **Keep Your Token Safe**:
- Never commit tokens to Git
- Never share your token publicly
- Treat like a password
- Store in password manager
- Regenerate if accidentally exposed
- Tokens in this guide are examples only

✓ **Best Practices**:
- Use token expiration (90 days recommended)
- Use least privilege scopes
- Regenerate tokens periodically
- Review active tokens regularly
- Use SSH keys for Git operations when possible

---

**Once complete, you'll have a GitHub repository ready for AWS deployment!**

For deployment instructions, see DEPLOYMENT_GUIDE.md
