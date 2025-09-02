# Manufacturing QC Cross-Check Monorepo

A comprehensive Quality Control cross-checking system built with FastAPI backend and React frontend.

## 🏗️ Project Structure

```
Manufacturing-QC-Cross-Check/
├── Manufacturing-QC-Cross-Check-Backend/    # FastAPI backend
├── Manufacturing-QC-Cross-Check-Frontend/   # React frontend
├── deploy/                                   # Deployment configurations
│   ├── deploy.sh                            # Main deployment script
│   ├── nginx.conf                           # Nginx configuration
│   └── init-db.sql                         # Database initialization
├── docker-compose.yml                       # Docker services configuration
├── .env                                     # Environment variables (generated)
├── uploads/                                 # File uploads directory
└── logs/                                    # Application logs

```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Git
- Linux/Ubuntu server (for production deployment)

### Local Development

1. **Clone the repositories** (temporary until monorepo migration):
   ```bash
   git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git
   git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Frontend.git
   ```

2. **Start the development environment**:
   ```bash
   docker-compose up -d --build
   ```

3. **Access the application**:
   - Frontend: http://localhost
   - Backend API: http://localhost/api
   - API Docs: http://localhost/docs

### Production Deployment

1. **Basic deployment**:
   ```bash
   ./deploy.sh
   ```

2. **Deployment with SSL** (for custom domains):
   ```bash
   ./deploy.sh --ssl yourdomain.com your@email.com
   ```

3. **Access your deployed application**:
   - Application: http://your-server-ip (or https://yourdomain.com with SSL)
   - API: http://your-server-ip/api
   - Docs: http://your-server-ip/docs

## 🔧 Configuration

### Environment Variables

The deployment script automatically generates:
- `DB_PASSWORD`: Secure database password
- `SECRET_KEY`: Application secret key

### Service Configuration

- **Backend**: FastAPI on port 8000 (internal)
- **Frontend**: React app served via Nginx on port 80 (internal)
- **Database**: PostgreSQL on port 5432 (internal only)
- **Proxy**: Nginx on ports 80/443 (external)

## 🐳 Docker Services

- **backend**: FastAPI application
- **frontend**: React application with Nginx
- **db**: PostgreSQL database
- **nginx**: Reverse proxy and load balancer
- **redis**: Caching layer (optional)

## 📋 Management Commands

### View Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs [backend|frontend|db|nginx|redis]
```

### Restart Services
```bash
docker-compose restart
```

### Update Application
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up -d --build
```

### Stop Services
```bash
docker-compose down
```

## 🔒 Security Features

- Internal networking for all services
- No external database access
- Nginx reverse proxy with CORS handling
- Secure credential generation
- Log rotation setup
- Systemd service for auto-restart

## 🚀 Deployment Architecture

```
Internet → Nginx (Port 80/443) → {
    / → Frontend (React App)
    /api → Backend (FastAPI)
    /docs → API Documentation
}

Backend ↔ Database (PostgreSQL)
Backend ↔ Redis (Caching)
```

## 📝 Migration to True Monorepo

This structure is ready for migration to a true monorepo:

1. Create single repository
2. Move both projects as subdirectories
3. Update deployment script repository URL
4. Maintain same deployment process

## 🐛 Troubleshooting

### Port Conflicts
The deployment script automatically handles port conflicts by:
- Stopping existing services
- Killing processes using required ports
- Using internal Docker networking

### Service Issues
```bash
# Check service health
docker-compose ps

# View specific service logs
docker-compose logs [service-name]

# Restart problematic service
docker-compose restart [service-name]
```

### Database Issues
```bash
# Access database
docker-compose exec db psql -U qc_user -d qc_system

# Reset database
docker-compose down -v
docker-compose up -d
```

## 📞 Support

For issues and questions:
1. Check service logs: `docker-compose logs`
2. Verify service status: `docker-compose ps`
3. Review deployment logs
4. Check network connectivity
