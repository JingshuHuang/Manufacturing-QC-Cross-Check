#!/bin/bash

# EC2 Deployment Script for Manufacturing QC Cross-Check System
# This script automates the deployment process on a fresh Ubuntu EC2 instance

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Configuration
APP_DIR="/opt/manufacturing-qc"
BACKEND_REPO="https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git"
FRONTEND_REPO="https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Frontend.git"

# Function to check if running on Ubuntu
check_ubuntu() {
    if [[ ! -f /etc/ubuntu-release ]] && [[ ! -f /etc/lsb-release ]]; then
        echo_error "This script is designed for Ubuntu systems only"
        exit 1
    fi
    echo_status "Ubuntu system detected"
}

# Function to update system
update_system() {
    echo_info "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo_status "System updated successfully"
}

# Function to install essential packages
install_essentials() {
    echo_info "Installing essential packages..."
    sudo apt install -y curl wget git htop unzip build-essential
    echo_status "Essential packages installed"
}

# Function to install Docker
install_docker() {
    echo_info "Installing Docker..."
    
    # Remove old Docker versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    
    echo_status "Docker installed successfully"
}

# Function to install Docker Compose
install_docker_compose() {
    echo_info "Installing Docker Compose..."
    
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo_status "Docker Compose installed successfully"
}

# Function to setup application directory
setup_app_directory() {
    echo_info "Setting up application directory..."
    
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
    cd $APP_DIR
    
    echo_status "Application directory created: $APP_DIR"
}

# Function to clone repositories
clone_repositories() {
    echo_info "Cloning repositories..."
    
    # Clone backend
    if [ -d "Manufacturing-QC-Cross-Check-Backend" ]; then
        echo_info "Backend repository exists, pulling latest changes..."
        cd Manufacturing-QC-Cross-Check-Backend
        git pull origin main
        cd ..
    else
        git clone $BACKEND_REPO
    fi
    
    # Clone frontend
    if [ -d "Manufacturing-QC-Cross-Check-Frontend" ]; then
        echo_info "Frontend repository exists, pulling latest changes..."
        cd Manufacturing-QC-Cross-Check-Frontend
        git pull origin main
        cd ..
    else
        git clone $FRONTEND_REPO
    fi
    
    echo_status "Repositories cloned successfully"
}

# Function to setup deployment files
setup_deployment_files() {
    echo_info "Setting up deployment files..."
    
    # Copy docker-compose.yml from backend to root
    if [ -f "Manufacturing-QC-Cross-Check-Backend/docker-compose.yml" ]; then
        cp Manufacturing-QC-Cross-Check-Backend/docker-compose.yml ./
    else
        echo_error "docker-compose.yml not found in backend repository"
        exit 1
    fi
    
    # Copy deploy directory from backend to root
    if [ -d "Manufacturing-QC-Cross-Check-Backend/deploy" ]; then
        cp -r Manufacturing-QC-Cross-Check-Backend/deploy ./
    else
        echo_error "deploy directory not found in backend repository"
        exit 1
    fi
    
    echo_status "Deployment files copied"
}

# Function to generate environment variables
generate_env() {
    echo_info "Generating environment variables..."
    
    DB_PASSWORD=$(openssl rand -base64 32)
    SECRET_KEY=$(openssl rand -hex 32)
    
    # Create .env file
    cat > .env << EOF
# Database Configuration
DB_PASSWORD=$DB_PASSWORD

# Application Environment
SECRET_KEY=$SECRET_KEY
NODE_ENV=production
DEBUG=false
EOF
    
    echo_status "Environment variables generated"
    echo_info "Database password: $DB_PASSWORD"
    echo_warning "Save the above credentials securely!"
}

# Function to create necessary directories
create_directories() {
    echo_info "Creating necessary directories..."
    
    mkdir -p uploads logs
    sudo chown -R $USER:$USER uploads logs
    
    echo_status "Directories created"
}

# Function to build and start services
deploy_services() {
    echo_info "Building and starting services..."
    
    # Check if user is in docker group
    if ! groups $USER | grep -q docker; then
        echo_warning "User not in docker group. You may need to logout and login again."
        echo_info "Attempting to use sudo for docker commands..."
        DOCKER_CMD="sudo docker-compose"
    else
        DOCKER_CMD="docker-compose"
    fi
    
    # Build and start services
    $DOCKER_CMD up -d --build
    
    echo_status "Services started"
}

# Function to wait for services and run migrations
finalize_deployment() {
    echo_info "Waiting for services to start..."
    sleep 60
    
    echo_info "Checking service status..."
    docker-compose ps
    
    echo_info "Running database migrations..."
    docker-compose exec -T backend alembic upgrade head || echo_warning "Migration failed, but continuing..."
    
    echo_status "Deployment finalized"
}

# Function to setup systemd service
setup_systemd_service() {
    echo_info "Setting up systemd service for auto-start..."
    
    sudo tee /etc/systemd/system/manufacturing-qc.service << EOF
[Unit]
Description=Manufacturing QC Cross-Check Application
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
    
    echo_status "Systemd service configured"
}

# Function to display deployment information
show_deployment_info() {
    # Get public IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
    
    echo ""
    echo_status "🎉 Deployment completed successfully!"
    echo ""
    echo "📍 Access URLs:"
    echo "🌐 Application: http://$PUBLIC_IP"
    echo "🔧 Backend API: http://$PUBLIC_IP/api"
    echo "📚 API Documentation: http://$PUBLIC_IP/docs"
    echo "❤️ Health Check: http://$PUBLIC_IP/health"
    echo ""
    echo "🔒 Important Information:"
    echo "💾 Application directory: $APP_DIR"
    echo "📁 Environment file: $APP_DIR/.env"
    echo ""
    echo "🛠️ Management Commands:"
    echo "📊 Check status: docker-compose ps"
    echo "📋 View logs: docker-compose logs"
    echo "🔄 Restart: docker-compose restart"
    echo "🛑 Stop: docker-compose down"
    echo "▶️ Start: docker-compose up -d"
    echo ""
}

# Main execution
main() {
    echo_info "🚀 Starting Manufacturing QC EC2 Deployment..."
    echo ""
    
    check_ubuntu
    update_system
    install_essentials
    install_docker
    install_docker_compose
    setup_app_directory
    clone_repositories
    setup_deployment_files
    generate_env
    create_directories
    deploy_services
    finalize_deployment
    setup_systemd_service
    show_deployment_info
    
    echo_status "✨ Deployment script completed!"
    echo_warning "Note: If you encounter Docker permission issues, logout and login again, then run:"
    echo_info "cd $APP_DIR && docker-compose restart"
}

# Check if script is run with sudo (not recommended)
if [[ $EUID -eq 0 ]]; then
   echo_error "This script should not be run as root for security reasons"
   echo_info "Please run as a regular user: ./ec2-deploy.sh"
   exit 1
fi

# Run main function
main "$@"
