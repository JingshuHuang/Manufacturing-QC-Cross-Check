#!/bin/bash

# Complete Manufacturing QC Monorepo Deployment Script for EC2
echo "🚀 Deploying Manufacturing QC Monorepo to EC2..."

# Configuration
APP_DIR="/opt/manufacturing-qc"
REPO_URL="https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git"  # Update this to your monorepo URL when ready

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo_error "This script should not be run as root for security reasons"
   echo_info "Please run as a regular user with sudo privileges"
   exit 1
fi

# Check for required tools
check_dependencies() {
    echo_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        echo_error "Docker is not installed. Installing Docker..."
        install_docker
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo_error "Docker Compose is not installed. Installing Docker Compose..."
        install_docker_compose
    fi
    
    if ! command -v git &> /dev/null; then
        echo_error "Git is not installed. Please install Git first."
        sudo apt update && sudo apt install -y git
    fi
    
    echo_status "All dependencies are installed"
}

# Install Docker
install_docker() {
    echo_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo_status "Docker installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    echo_info "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo_status "Docker Compose installed successfully"
}

# Stop any existing services
cleanup_existing() {
    echo_info "Stopping existing services..."
    cd $APP_DIR 2>/dev/null || true
    
    # Stop various docker-compose configurations
    sudo docker-compose down 2>/dev/null || true
    sudo docker-compose -f docker-compose.yml down 2>/dev/null || true
    sudo docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    sudo docker-compose -f Manufacturing-QC-Cross-Check-Backend/docker-compose.full.yml down 2>/dev/null || true
    
    # Kill any processes using ports
    echo_info "Freeing up ports..."
    sudo pkill -f "postgres" 2>/dev/null || true
    sudo fuser -k 5432/tcp 2>/dev/null || true
    sudo fuser -k 80/tcp 2>/dev/null || true
    sudo fuser -k 443/tcp 2>/dev/null || true
    sudo fuser -k 8000/tcp 2>/dev/null || true
    sudo fuser -k 3000/tcp 2>/dev/null || true
    
    echo_status "Cleanup completed"
}

# Setup monorepo structure
setup_monorepo() {
    echo_info "Setting up monorepo structure..."
    
    # Create application directory
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
    cd $APP_DIR
    
    # For now, clone both repositories separately
    # In the future, this will be replaced with a single monorepo clone
    
    # Clone or update backend repository
    if [ -d "Manufacturing-QC-Cross-Check-Backend/.git" ]; then
        echo_status "Updating backend repository..."
        cd Manufacturing-QC-Cross-Check-Backend
        git pull origin main
        cd ..
    else
        echo_status "Cloning backend repository..."
        git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git
    fi
    
    # Clone or update frontend repository
    if [ -d "Manufacturing-QC-Cross-Check-Frontend/.git" ]; then
        echo_status "Updating frontend repository..."
        cd Manufacturing-QC-Cross-Check-Frontend
        git pull origin main
        cd ..
    else
        echo_status "Cloning frontend repository..."
        git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Frontend.git
    fi
    
    # Copy monorepo deployment files from backend to root
    echo_info "Setting up monorepo deployment configuration..."
    
    # Copy deployment files to root directory if they exist in backend
    if [ -f "Manufacturing-QC-Cross-Check-Backend/docker-compose.yml" ]; then
        cp Manufacturing-QC-Cross-Check-Backend/docker-compose.yml ./
    fi
    
    if [ -d "Manufacturing-QC-Cross-Check-Backend/deploy" ]; then
        cp -r Manufacturing-QC-Cross-Check-Backend/deploy ./
    fi
    
    echo_status "Monorepo structure setup completed"
}

# Configure environment
configure_environment() {
    echo_info "Configuring environment..."
    
    # Generate secure passwords and keys
    DB_PASSWORD=$(openssl rand -base64 32)
    SECRET_KEY=$(openssl rand -hex 32)
    
    # Create environment file for Docker Compose
    cat > .env << EOF
# Database Configuration
DB_PASSWORD=$DB_PASSWORD

# Application Environment
SECRET_KEY=$SECRET_KEY
NODE_ENV=production
DEBUG=false
EOF
    
    # Create necessary directories
    mkdir -p uploads logs
    sudo chown -R $USER:$USER uploads logs
    
    echo_status "Environment configured"
}

# Deploy services
deploy_services() {
    echo_info "Building and starting all services..."
    
    # Build and start all services
    sudo docker-compose up -d --build
    
    # Wait for services to start
    echo_info "Waiting for services to start..."
    sleep 45
    
    # Check service health
    echo_info "Checking service health..."
    if sudo docker-compose ps | grep -q "Up"; then
        echo_status "Services started successfully!"
        
        # Wait a bit more for database to be ready
        sleep 15
        
        # Run database migrations
        echo_info "Running database migrations..."
        sudo docker-compose exec -T backend alembic upgrade head || echo_warning "Migration may have failed, but continuing..."
        
        return 0
    else
        echo_error "Service startup failed"
        return 1
    fi
}

# Display deployment information
show_deployment_info() {
    # Get public IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
    
    echo ""
    echo_status "🎉 Monorepo Deployment Completed Successfully!"
    echo ""
    echo "📍 Access URLs:"
    echo "🌐 Complete Application: http://$PUBLIC_IP"
    echo "🔧 Backend API: http://$PUBLIC_IP/api"
    echo "📚 API Documentation: http://$PUBLIC_IP/docs"
    echo "❤️ Health Check: http://$PUBLIC_IP/health"
    echo ""
    echo "🔒 Credentials:"
    echo "🗄️ Database Password: $DB_PASSWORD"
    echo "🔑 Secret Key: $SECRET_KEY"
    echo ""
    echo "📝 Important: Save these credentials securely!"
    echo ""
    echo "🐳 Docker Services:"
    sudo docker-compose ps
}

# Setup system services
setup_system_services() {
    echo_info "Setting up system services..."
    
    # Setup log rotation
    sudo mkdir -p /var/log/manufacturing-qc
    sudo tee /etc/logrotate.d/manufacturing-qc << EOF
/var/log/manufacturing-qc/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
    
    # Create systemd service for auto-start
    sudo tee /etc/systemd/system/manufacturing-qc.service << EOF
[Unit]
Description=Manufacturing QC Cross-Check Monorepo Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable manufacturing-qc.service
    
    echo_status "System services configured"
}

# Setup SSL certificates (optional)
setup_ssl() {
    local domain="$1"
    local email="$2"
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        echo_info "SSL setup skipped. Use: ./deploy.sh --ssl yourdomain.com your@email.com"
        return 0
    fi
    
    echo_info "Setting up SSL certificate for $domain..."
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    # Update nginx config with domain
    sudo sed -i "s/server_name _;/server_name $domain www.$domain;/" /etc/nginx/conf.d/default.conf
    
    # Test nginx config
    sudo nginx -t
    
    # Obtain SSL certificate
    sudo certbot --nginx -d $domain -d www.$domain --email $email --agree-tos --non-interactive
    
    # Setup auto-renewal
    sudo crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | sudo crontab -
    
    echo_status "SSL certificate setup completed for $domain"
}

# Main deployment flow
main() {
    echo_info "Starting Manufacturing QC Monorepo Deployment..."
    
    # Parse command line arguments for SSL setup
    SSL_DOMAIN=""
    SSL_EMAIL=""
    if [[ "$1" == "--ssl" && -n "$2" && -n "$3" ]]; then
        SSL_DOMAIN="$2"
        SSL_EMAIL="$3"
        shift 3
    fi
    
    check_dependencies
    cleanup_existing
    setup_monorepo
    configure_environment
    
    if deploy_services; then
        show_deployment_info
        setup_system_services
        setup_ssl "$SSL_DOMAIN" "$SSL_EMAIL"
        echo_status "✨ Deployment complete! The application will automatically start on boot."
    else
        echo_error "Deployment failed. Checking logs..."
        echo "📋 Service Status:"
        sudo docker-compose ps
        echo ""
        echo "📋 Backend Logs:"
        sudo docker-compose logs backend
        echo ""
        echo "📋 Frontend Logs:"
        sudo docker-compose logs frontend
        echo ""
        echo "📋 Database Logs:"
        sudo docker-compose logs db
        exit 1
    fi
}

# Run main function
main "$@"
