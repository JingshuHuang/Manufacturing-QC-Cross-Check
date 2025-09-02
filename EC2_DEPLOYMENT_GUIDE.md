# 🚀 EC2 Deployment Guide - Manufacturing QC System

**Simple step-by-step guide to deploy your Manufacturing QC application on AWS EC2**

## ⚡ Quick Start (5 minutes)

### Option A: Upload and Run Script (Recommended)

1. **Launch EC2 instance** with Ubuntu 22.04 LTS
2. **Upload the deployment script** to your EC2 (see Step 3 below)
3. **Run the script** on your EC2
4. **Access your app** at `http://YOUR-EC2-IP`

### Option B: Manual Commands

If you prefer to run commands manually, follow the detailed step-by-step guide below.

## 📋 What You Need

- ✅ AWS Account 
- ✅ Credit card (for EC2 costs)
- ✅ 15 minutes of time

## 🎯 Detailed Step-by-Step Guide

### 🔥 Step 1: Launch EC2 Instance (2 minutes)

1. **Go to AWS Console**: https://console.aws.amazon.com
2. **Search for "EC2"** and click on it
3. **Click "Launch Instance"** (big orange button)
4. **Fill in these settings**:
   ```
   Name: manufacturing-qc-app
   Image: Ubuntu Server 22.04 LTS (should be selected by default)
   Instance type: t3.medium (select from dropdown)
   Key pair: Create new key pair
     - Name: manufacturing-qc-key
     - Download the .pem file (SAVE THIS FILE!)
   ```
5. **Configure Security Group** (click "Edit" next to Network settings):
   ```
   ✅ SSH (22) - Your IP
   ✅ HTTP (80) - Anywhere (0.0.0.0/0)
   ✅ HTTPS (443) - Anywhere (0.0.0.0/0)
   ```
6. **Change Storage** to 20 GB (click "Edit" next to Configure storage)
7. **Click "Launch Instance"**
8. **Wait 2-3 minutes** for instance to start
9. **Copy the Public IP address** (you'll need this!)

### 💻 Step 2: Connect to Your Server (1 minute)

**Option A: Using AWS Console (Easiest)**
1. Go to your EC2 instance
2. Click "Connect" button
3. Choose "EC2 Instance Connect"
4. Click "Connect" - you're now in the terminal!

**Option B: Using Your Computer's Terminal**

**Windows (PowerShell):**
```powershell
ssh -i "C:\Downloads\manufacturing-qc-key.pem" ubuntu@YOUR-EC2-PUBLIC-IP
```

**Mac/Linux:**
```bash
chmod 400 ~/Downloads/manufacturing-qc-key.pem
ssh -i "~/Downloads/manufacturing-qc-key.pem" ubuntu@YOUR-EC2-PUBLIC-IP
```

### 🚀 Step 3: Deploy the Application (5 minutes)

**Method A: Using the Deployment Script (Recommended)**

1. **Download the deployment script** from your local machine:
   - The script is located at: `e:\Test\GenAi Labs\ec2-deploy.sh`

2. **Upload the script to EC2** using one of these methods:

   **Option 1: Using SCP (from your Windows machine)**
   ```powershell
   scp -i "C:\Downloads\manufacturing-qc-key.pem" "e:\Test\GenAi Labs\ec2-deploy.sh" ubuntu@YOUR-EC2-PUBLIC-IP:~/
   ```

   **Option 2: Copy-paste the script content**
   - Open `e:\Test\GenAi Labs\ec2-deploy.sh` in your text editor
   - Copy all the content
   - In your EC2 terminal, create the file:
   ```bash
   nano ~/ec2-deploy.sh
   # Paste the content, then save with Ctrl+X, Y, Enter
   ```

3. **Make the script executable and run it**:
   ```bash
   chmod +x ~/ec2-deploy.sh
   ./ec2-deploy.sh
   ```

**Method B: Manual Step-by-Step Commands**

If you prefer to run commands manually, copy and paste these commands one by one:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git htop unzip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create application directory
sudo mkdir -p /opt/manufacturing-qc
sudo chown ubuntu:ubuntu /opt/manufacturing-qc
cd /opt/manufacturing-qc

# Clone repositories
git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git
git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Frontend.git

# Copy deployment files
cp Manufacturing-QC-Cross-Check-Backend/docker-compose.yml ./
cp -r Manufacturing-QC-Cross-Check-Backend/deploy ./

# Generate environment variables
DB_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -hex 32)

# Create .env file
cat > .env << EOF
DB_PASSWORD=$DB_PASSWORD
SECRET_KEY=$SECRET_KEY
NODE_ENV=production
DEBUG=false
EOF

# Create directories
mkdir -p uploads logs

# Start services
docker-compose up -d --build

# Wait and run migrations
sleep 60
docker-compose exec -T backend alembic upgrade head
```

### 🎉 Step 4: Access Your Application

After the script finishes (5-10 minutes), you'll see:

```
✅ Deployment completed successfully!
🌐 Application: http://YOUR-EC2-IP
📚 API docs: http://YOUR-EC2-IP/docs
```

**Open your browser** and go to `http://YOUR-EC2-IP`

## ✅ Verification Checklist

After deployment, check these:

- [ ] **Frontend loads**: Go to `http://YOUR-EC2-IP` - you should see the Manufacturing QC interface
- [ ] **API works**: Go to `http://YOUR-EC2-IP/docs` - you should see API documentation
- [ ] **Upload test**: Try uploading a file through the interface

## �️ Troubleshooting

### ❌ Common Issues & Solutions

**1. "Connection refused" when accessing the website**
```bash
# Check if services are running
docker-compose ps

# If services are down, restart them
docker-compose up -d
```

**2. "Application not loading"**
```bash
# Check logs to see what's wrong
docker-compose logs

# Restart everything
docker-compose restart
```

**3. "Can't SSH into EC2"**
- ✅ Check Security Group allows SSH (port 22) from your IP
- ✅ Use correct username: `ubuntu` (not `ec2-user`)
- ✅ Check your .pem file path is correct

**4. "Services keep crashing"**
```bash
# Check if you have enough memory
free -h

# If low memory, upgrade to t3.medium or larger instance
```

### 🔧 Useful Commands

**Check everything is working:**
```bash
cd /opt/manufacturing-qc
docker-compose ps
```

**See what went wrong:**
```bash
docker-compose logs
```

**Restart the application:**
```bash
docker-compose restart
```

**Update the application:**
```bash
cd /opt/manufacturing-qc
git -C Manufacturing-QC-Cross-Check-Backend pull
git -C Manufacturing-QC-Cross-Check-Frontend pull
docker-compose up -d --build
```

## 💰 Costs

**Estimated monthly costs:**
- **t3.medium**: ~$30/month (recommended)
- **t3.small**: ~$15/month (minimum)
- **Storage**: ~$2/month for 20GB

**� Cost-saving tip**: Stop your EC2 instance when not using it!

## 🔒 Security Notes

**✅ Good practices:**
- Keep your .pem key file safe
- Only allow SSH from your IP
- Use HTTPS in production (see SSL setup below)

**⚠️ Important**: Change these defaults in production:
- Database passwords
- Secret keys
- Security group settings

## 🌟 Next Steps

### Add Your Domain Name

1. **Buy a domain** (like GoDaddy, Namecheap)
2. **Point domain to EC2 IP**:
   - Create A record: `yourdomain.com` → `YOUR-EC2-IP`
3. **Setup SSL certificate**:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d yourdomain.com
   ```

### Setup Automatic Backups

```bash
# Create backup script
echo "docker-compose exec -T db pg_dump -U qc_user qc_system > /opt/backups/backup_\$(date +%Y%m%d).sql" > backup.sh
chmod +x backup.sh

# Run daily at 2 AM
(crontab -l; echo "0 2 * * * /home/ubuntu/backup.sh") | crontab -
```

## 🆘 Need Help?

**If something goes wrong:**

1. **Check the logs**: `docker-compose logs`
2. **Verify services**: `docker-compose ps`  
3. **Restart everything**: `docker-compose restart`
4. **Check AWS console** for instance status

**Still stuck?** 
- Check AWS documentation
- Verify security group settings
- Ensure instance has enough memory/disk space

## � Success!

**You now have:**
- ✅ Manufacturing QC system running on AWS
- ✅ Professional-grade deployment
- ✅ Scalable infrastructure
- ✅ Easy management commands

**Your application is live at**: `http://YOUR-EC2-IP`

**Share it with your team and start uploading QC documents!** 🚀
