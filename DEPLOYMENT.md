# CI/CD Deployment Guide

This guide covers setting up **free** continuous deployment for the Homebase fitness tracker:
- **Frontend**: GitHub Pages (auto-deploy via GitHub Actions)
- **Backend**: Render.com (auto-deploy on push)
- **Database**: MongoDB Atlas (free tier)

## Prerequisites

1. GitHub account
2. Render account (free): https://render.com/
3. MongoDB Atlas account (free): https://www.mongodb.com/cloud/atlas

---

## Part 1: MongoDB Atlas Setup (Free Database)

### Step 1: Create MongoDB Atlas Cluster

1. Go to https://www.mongodb.com/cloud/atlas and sign up/login
2. Click **"Build a Database"**
3. Choose **"M0 Free"** tier
4. Select a cloud provider and region (choose closest to your Render backend region)
5. Name your cluster (e.g., `homebase-cluster`)
6. Click **"Create"**

### Step 2: Configure Database Access

1. In **Database Access**, click **"Add New Database User"**
   - Authentication Method: Password
   - Username: `homebase-admin` (or your choice)
   - Password: Generate a secure password (save it!)
   - Database User Privileges: **Read and write to any database**
   - Click **"Add User"**

### Step 3: Configure Network Access

1. In **Network Access**, click **"Add IP Address"**
2. Click **"Allow Access from Anywhere"** (0.0.0.0/0)
   - Note: Render uses dynamic IPs, so this is required for free tier
3. Click **"Confirm"**

### Step 4: Get Connection String

1. Go to **Database** → Click **"Connect"** on your cluster
2. Choose **"Connect your application"**
3. Driver: **Node.js**, Version: **5.5 or later**
4. Copy the connection string, it looks like:
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. Replace `<username>` and `<password>` with your credentials
6. **Save this connection string** - you'll need it for Render!

---

## Part 2: Backend Deployment on Render (Free)

### Step 1: Push Your Code to GitHub

Make sure your code is pushed to your GitHub repository:
```bash
git add .
git commit -m "Add CI/CD configuration"
git push origin master
```

### Step 2: Create Render Service

#### Option A: Using Blueprint (Recommended - Infrastructure as Code)

1. Go to https://dashboard.render.com/ and login
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub repository (`kevzhg/Homebase`)
4. Render will detect the `render.yaml` file
5. Give your blueprint a name (e.g., `homebase-production`)
6. Click **"Apply"**

#### Option B: Manual Setup

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository
3. Configure:
   - **Name**: `homebase-api`
   - **Region**: Oregon (or closest to you)
   - **Branch**: `master`
   - **Runtime**: Node
   - **Build Command**: `npm install && npm run build:server`
   - **Start Command**: `npm run server`
   - **Plan**: Free

### Step 3: Add Environment Variables

In your Render service dashboard:

1. Go to **"Environment"** tab
2. Add these environment variables:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `PORT` | `8000` |
| `MONGODB_URI` | `mongodb+srv://your-connection-string...` (from Atlas) |
| `MONGODB_DB` | `homebase` |
| `MONGODB_COLLECTION_TRAININGS` | `trainings` |
| `MONGODB_COLLECTION_MEALS` | `meals` |
| `MONGODB_COLLECTION_WEIGHT` | `weight` |
| `MONGODB_COLLECTION_ONIGIRI` | `onigiri` |
| `MONGODB_COLLECTION_PROGRAMS` | `programs` |
| `MONGODB_COLLECTION_EXERCISES` | `exercises` |

3. Click **"Save Changes"**

### Step 4: Get Your API URL

After deployment completes (5-10 minutes):
- Your API will be live at: `https://homebase-api.onrender.com`
- **Copy this URL** - you'll need it for the frontend!

**Note**: Free tier services sleep after 15 minutes of inactivity. First request after sleep takes ~30 seconds to wake up.

---

## Part 3: Frontend Deployment on GitHub Pages (Free)

### Step 1: Update API URL in Frontend

1. Open `index.html`
2. Find the script block at the bottom with `API_BASE_URL`
3. Update the Render URL to match your deployed backend:
   ```javascript
   if (location.hostname.endsWith('github.io')) {
     window.API_BASE_URL = 'https://homebase-api.onrender.com/api';
   }
   ```
4. Save and commit:
   ```bash
   git add index.html
   git commit -m "Update API URL for production"
   git push origin master
   ```

### Step 2: Enable GitHub Pages

1. Go to your GitHub repository settings
2. Navigate to **Pages** (in sidebar)
3. Under **Source**, select:
   - **Deploy from a branch**
   - Branch: `master`
   - Folder: `/docs`
4. Click **"Save"**

### Step 3: Enable GitHub Actions

1. In your repository, go to **Settings** → **Actions** → **General**
2. Under **"Workflow permissions"**, ensure:
   - ✅ Read and write permissions
   - ✅ Allow GitHub Actions to create and approve pull requests
3. Click **"Save"**

4. Go to **Settings** → **Pages**
5. Under **"Build and deployment"**, change Source to:
   - **GitHub Actions** (instead of "Deploy from a branch")

### Step 4: Trigger Deployment

The GitHub Actions workflow will automatically run on every push to `master`. To trigger it now:

```bash
git push origin master
```

Or manually trigger it:
1. Go to **Actions** tab in your repository
2. Click **"Deploy to GitHub Pages"** workflow
3. Click **"Run workflow"** → **"Run workflow"**

### Step 5: Access Your Site

After the workflow completes (~2-3 minutes):
- Your site will be live at: `https://kevzhg.github.io/Homebase/`
- Check the **Actions** tab for deployment status
- Check **Settings** → **Pages** for the published URL

---

## Part 4: Verify Everything Works

### Test the Backend

```bash
# Check API health
curl https://homebase-api.onrender.com/api/programs

# Should return JSON array (empty or with data)
```

### Test the Frontend

1. Visit `https://kevzhg.github.io/Homebase/`
2. Open browser DevTools (F12) → Console
3. Check for API connection errors
4. Try adding a workout or meal
5. Verify data persists after page refresh

---

## Continuous Deployment Flow

Once set up, deployments are automatic:

### Frontend Updates
1. Edit frontend code (`src/app.ts`, `index.html`, `styles.css`)
2. Commit and push:
   ```bash
   git add .
   git commit -m "Update frontend feature"
   git push origin master
   ```
3. GitHub Actions automatically builds and deploys to Pages (~2-3 min)

### Backend Updates
1. Edit backend code (`src/server.ts`, etc.)
2. Commit and push:
   ```bash
   git add .
   git commit -m "Update API endpoint"
   git push origin master
   ```
3. Render automatically rebuilds and redeploys (~5-10 min)

### Monitor Deployments
- **Frontend**: GitHub repo → **Actions** tab
- **Backend**: Render dashboard → **Logs** tab

---

## Troubleshooting

### Frontend not loading or API errors

**Check API URL**:
- Open `index.html` and verify `API_BASE_URL` matches your Render service URL
- Open browser DevTools → Console for specific errors

**CORS Issues**:
- Ensure `src/server.ts` allows your GitHub Pages origin:
  ```typescript
  app.use(cors({
    origin: ['http://localhost:3000', 'https://kevzhg.github.io']
  }));
  ```

**GitHub Pages 404**:
- Ensure `docs/` folder exists in your repository
- Verify GitHub Pages source is set to `master` branch `/docs` folder (or GitHub Actions)
- Check that `docs/.nojekyll` file exists

### Backend crashes or 500 errors

**Check Render Logs**:
1. Go to Render dashboard
2. Click your service
3. Check **Logs** tab for errors

**Common issues**:
- Invalid MongoDB connection string (check `MONGODB_URI`)
- Missing environment variables
- MongoDB Atlas network access not configured

**Test MongoDB connection locally**:
```bash
# Create .env file with your Atlas credentials
echo 'MONGODB_URI=mongodb+srv://...' > .env
echo 'MONGODB_DB=homebase' >> .env

# Test connection
npm run server
```

### Render service sleeping

Free Render services sleep after 15 minutes of inactivity. First request takes ~30 seconds to wake up.

**Solution**: Accept the delay, or upgrade to a paid plan for always-on service.

---

## Free Tier Limits

### GitHub Pages
- ✅ Unlimited bandwidth
- ✅ Unlimited builds
- ✅ Custom domain support

### Render Free Tier
- ✅ 750 hours/month (enough for 1 service)
- ⚠️ Sleeps after 15 min inactivity
- ⚠️ 30-second wake-up time
- ✅ Auto-deploy on push
- ⚠️ Services shut down after 90 days of inactivity

### MongoDB Atlas Free Tier (M0)
- ✅ 512 MB storage
- ✅ Shared RAM
- ✅ Unlimited connections (reasonable use)
- ⚠️ Limited to 100 database operations/second

---

## Alternative Free Hosting Options

If you need alternatives:

### Backend Alternatives to Render
- **Railway** (free tier: 500 hours/month, no sleep): https://railway.app/
- **Fly.io** (free tier: 3 VMs, always-on): https://fly.io/
- **Cyclic** (unlimited apps, no sleep): https://www.cyclic.sh/
- **Vercel** (serverless, no sleep, but requires Edge-compatible code): https://vercel.com/

### Database Alternatives to Atlas
- **Supabase** (PostgreSQL, 500MB free): https://supabase.com/
- **PlanetScale** (MySQL, 5GB free): https://planetscale.com/
- **Neon** (PostgreSQL, serverless): https://neon.tech/
- **Railway** (built-in PostgreSQL/MongoDB): https://railway.app/

### Frontend Alternatives to GitHub Pages
- **Vercel** (unlimited sites): https://vercel.com/
- **Netlify** (100GB bandwidth/month): https://www.netlify.com/
- **Cloudflare Pages** (unlimited bandwidth): https://pages.cloudflare.com/

---

## Next Steps

After deploying:

1. **Monitor usage**: Check Render and Atlas dashboards for usage stats
2. **Set up alerts**: Configure Render to email you on deployment failures
3. **Add custom domain** (optional): Both GitHub Pages and Render support custom domains
4. **Enable HTTPS**: Both platforms provide free SSL certificates automatically
5. **Backup database**: Export MongoDB data periodically from Atlas

---

## Cost Optimization Tips

- Use **MongoDB Atlas free tier M0** (512MB) - plenty for this app
- Keep backend on **Render free tier** - accept 30s wake-up delay
- Use **GitHub Pages** for frontend (totally free, no limits)
- Consider upgrading only the backend to Render Starter ($7/month) if you need always-on

**Total monthly cost**: $0 (with sleep delay) or $7 (always-on backend)

---

## Support

- **Render Docs**: https://render.com/docs
- **GitHub Pages Docs**: https://docs.github.com/en/pages
- **MongoDB Atlas Docs**: https://www.mongodb.com/docs/atlas/
- **GitHub Actions Docs**: https://docs.github.com/en/actions
