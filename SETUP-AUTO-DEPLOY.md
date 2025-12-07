# Quick Setup: Enable Auto-Deployment

Since you already have manual deployments running, here's how to enable automatic CI/CD:

---

## ✅ Step 1: Enable GitHub Actions for Pages (2 minutes)

Your GitHub Actions workflow is already committed. Now enable it:

### 1a. Change GitHub Pages Source
1. Go to: https://github.com/kevzhg/Homebase/settings/pages
2. Under **"Build and deployment"**:
   - **Source**: Change from "Deploy from a branch" to **"GitHub Actions"**
3. Click **"Save"**

### 1b. Enable Workflow Permissions
1. Go to: https://github.com/kevzhg/Homebase/settings/actions
2. Scroll to **"Workflow permissions"**
3. Select: ✅ **"Read and write permissions"**
4. Check: ✅ **"Allow GitHub Actions to create and approve pull requests"**
5. Click **"Save"**

### 1c. Trigger First Auto-Deploy
```bash
# Push your CI/CD changes to trigger the workflow
git push origin master
```

### 1d. Monitor Deployment
- Go to: https://github.com/kevzhg/Homebase/actions
- Watch the **"Deploy to GitHub Pages"** workflow run
- Takes ~2-3 minutes
- Once complete, check: https://kevzhg.github.io/Homebase/

---

## ✅ Step 2: Enable Render Auto-Deploy (3 minutes)

Your `render.yaml` is already committed. Now enable auto-deploy on Render:

### 2a. Update Existing Render Service

1. Go to your Render dashboard: https://dashboard.render.com/
2. Click your existing service (e.g., `homebase-50dv` or similar)
3. Go to **"Settings"** tab

### 2b. Enable Auto-Deploy

Scroll to **"Build & Deploy"** section:
- **Auto-Deploy**: Toggle to **"Yes"**
  - This makes Render automatically deploy when you push to `master`

### 2c. Optional: Switch to Blueprint (Recommended)

If you want to use the `render.yaml` Infrastructure as Code:

1. In Render dashboard, go to **"Blueprint"** tab (or create new Blueprint)
2. Click **"New Blueprint Instance"**
3. Connect repository: `kevzhg/Homebase`
4. Branch: `master`
5. Blueprint Name: `homebase-production`
6. Render will detect `render.yaml` and show all services
7. **Important**: Add environment variable:
   - Key: `MONGODB_URI`
   - Value: Your MongoDB Atlas connection string (from existing service)
8. Click **"Apply"**

**Note**: If switching to Blueprint, you may want to delete your old manual service afterward to avoid conflicts.

### 2d. Verify Auto-Deploy Works

```bash
# Make a small change to test
echo "# Test auto-deploy" >> README.md
git add README.md
git commit -m "Test auto-deploy"
git push origin master
```

- Watch Render dashboard for automatic deployment (~5-10 min)
- Check: https://homebase-50dv.onrender.com/api/programs

---

## ✅ Step 3: Verify Environment Variables on Render

Make sure your Render service has all these environment variables:

Go to your service → **"Environment"** tab:

| Key | Value | Status |
|-----|-------|--------|
| `NODE_ENV` | `production` | Should exist |
| `PORT` | `8000` | Should exist |
| `MONGODB_URI` | `mongodb+srv://...` | **Must exist** |
| `MONGODB_DB` | `homebase` | Check/add |
| `MONGODB_COLLECTION_TRAININGS` | `trainings` | Check/add |
| `MONGODB_COLLECTION_MEALS` | `meals` | Check/add |
| `MONGODB_COLLECTION_WEIGHT` | `weight` | Check/add |
| `MONGODB_COLLECTION_ONIGIRI` | `onigiri` | Check/add |
| `MONGODB_COLLECTION_PROGRAMS` | `programs` | Check/add |
| `MONGODB_COLLECTION_EXERCISES` | `exercises` | Check/add |

Add any missing variables and click **"Save Changes"**.

---

## ✅ Step 4: Test the Full Pipeline

### 4a. Make a Test Change
```bash
# Edit something visible (e.g., app title)
# Then commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push origin master
```

### 4b. Watch Both Deployments

**GitHub Pages** (Frontend):
- https://github.com/kevzhg/Homebase/actions
- Should start immediately
- Takes ~2-3 minutes
- Check result: https://kevzhg.github.io/Homebase/

**Render** (Backend):
- https://dashboard.render.com/
- Click your service → **"Events"** tab
- Should show "Deploy triggered by push"
- Takes ~5-10 minutes
- Check result: https://homebase-50dv.onrender.com/api/programs

---

## 🎯 Quick Reference: What Happens Now

### When you push to `master`:

1. **GitHub Actions runs automatically**:
   ```
   Push to master → Build TypeScript → Deploy to Pages → Live in 2-3 min
   ```

2. **Render deploys automatically**:
   ```
   Push to master → Build server → Deploy API → Live in 5-10 min
   ```

3. **No manual steps needed!**

---

## 🔧 Troubleshooting

### GitHub Actions not running?
- Check: https://github.com/kevzhg/Homebase/settings/actions
- Ensure **Actions permissions** are enabled
- Verify **Workflow permissions** are "Read and write"

### Render not auto-deploying?
- Check service **Settings** → **Build & Deploy**
- Ensure **Auto-Deploy** is "Yes"
- Verify **Branch** is set to `master`
- Check **Logs** tab for errors

### Old Pages deployment still showing?
- GitHub Pages may cache for a few minutes
- Hard refresh: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
- Check **Actions** tab to confirm new deployment completed
- May take 1-2 minutes to propagate after workflow completes

### API not connecting?
- Verify `MONGODB_URI` is set correctly on Render
- Check Render **Logs** tab for connection errors
- Ensure MongoDB Atlas **Network Access** allows all IPs (0.0.0.0/0)

---

## 📊 Monitoring Your Deployments

### GitHub Pages Status
- **Actions tab**: https://github.com/kevzhg/Homebase/actions
- **Settings → Pages**: https://github.com/kevzhg/Homebase/settings/pages
- Shows last deployment time and status

### Render Status
- **Dashboard**: https://dashboard.render.com/
- **Events tab**: Shows all deployments
- **Logs tab**: Shows build and runtime logs
- **Metrics tab**: Shows request/response times

---

## 🎉 You're Done!

Your CI/CD pipeline is now active. Every time you push to `master`:
- ✅ Frontend auto-deploys to GitHub Pages (2-3 min)
- ✅ Backend auto-deploys to Render (5-10 min)
- ✅ Both sites update automatically

**No more manual deployments!** 🚀

---

## Optional: Add Status Badges to README

Want to show build status in your README? Add these badges:

```markdown
![Deploy to GitHub Pages](https://github.com/kevzhg/Homebase/actions/workflows/deploy.yml/badge.svg)
```

Shows green checkmark when deployments succeed, red X when they fail.
