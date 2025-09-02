# 🚀 Quick EC2 Deployment Instructions

## 📦 What You Have
- ✅ Deployment script: `e:\Test\GenAi Labs\ec2-deploy.sh`
- ✅ PowerShell script: `e:\Test\GenAi Labs\ec2-deploy.ps1`
- ✅ Docker config: `e:\Test\GenAi Labs\docker-compose.yml`

## 🎯 3 Ways to Deploy

### Method 1: Automated PowerShell Script (Windows Users)

**Step 1**: Launch EC2 instance (Ubuntu 22.04, t3.medium, allow SSH/HTTP/HTTPS)

**Step 2**: Run this command in PowerShell:
```powershell
.\ec2-deploy.ps1 -EC2PublicIP "YOUR-EC2-IP" -KeyFilePath "C:\Downloads\your-key.pem"
```

✅ **Done!** The script handles everything automatically.

---

### Method 2: Upload and Run Script

**Step 1**: Launch EC2 instance

**Step 2**: Upload the deployment script:
```powershell
# From your Windows machine
scp -i "C:\Downloads\your-key.pem" "e:\Test\GenAi Labs\ec2-deploy.sh" ubuntu@YOUR-EC2-IP:~/
```

**Step 3**: Connect to EC2 and run:
```bash
ssh -i "C:\Downloads\your-key.pem" ubuntu@YOUR-EC2-IP
chmod +x ~/ec2-deploy.sh
./ec2-deploy.sh
```

✅ **Done!** Wait 5-10 minutes for completion.

---

### Method 3: Manual Commands (Step by Step)

**Step 1**: Launch EC2 and connect via SSH

**Step 2**: Copy-paste these commands one by one:

```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# 3. Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Setup application
sudo mkdir -p /opt/manufacturing-qc
sudo chown ubuntu:ubuntu /opt/manufacturing-qc
cd /opt/manufacturing-qc

# 5. Get your code
git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git
git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Frontend.git

# 6. Setup configuration
cp Manufacturing-QC-Cross-Check-Backend/docker-compose.yml ./
cp -r Manufacturing-QC-Cross-Check-Backend/deploy ./

# 7. Create environment
cat > .env << EOF
DB_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -hex 32)
NODE_ENV=production
DEBUG=false
EOF

# 8. Create directories
mkdir -p uploads logs

# 9. Start everything
docker-compose up -d --build

# 10. Wait and setup database
sleep 60
docker-compose exec -T backend alembic upgrade head
```

**Step 3**: Check if everything is running:
```bash
docker-compose ps
```

✅ **Done!** Your app is at `http://YOUR-EC2-IP`

---

## 🎉 Success Verification

After deployment, verify these work:

1. **Frontend**: `http://YOUR-EC2-IP` (should show the app)
2. **API Docs**: `http://YOUR-EC2-IP/docs` (should show Swagger UI)
3. **Health**: `http://YOUR-EC2-IP/health` (should return OK)

## ⚡ Recommended Approach

**For beginners**: Use Method 1 (PowerShell script)
**For control**: Use Method 3 (manual commands)
**For speed**: Use Method 2 (upload script)

## 🔧 If Something Goes Wrong

```bash
# Check what's running
docker-compose ps

# See error logs
docker-compose logs

# Restart everything
docker-compose restart
```

## 💡 Quick Tips

- **Instance size**: Use t3.medium (t3.small might be too small)
- **Storage**: 20 GB minimum
- **Security**: Allow ports 22, 80, 443 in security group
- **Cost**: ~$30/month for t3.medium (stop when not using)

Your app will be live at `http://YOUR-EC2-IP` after deployment! 🚀
