# Manufacturing QC Cross-Check Monorepo Makefile

.PHONY: help build up down restart logs status clean deploy

# Default target
help: ## Show this help message
	@echo "Manufacturing QC Cross-Check Monorepo"
	@echo "====================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development commands
build: ## Build all services
	docker-compose build

up: ## Start all services
	docker-compose up -d

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## Show logs for all services
	docker-compose logs -f

status: ## Show status of all services
	docker-compose ps

# Specific service commands
backend-logs: ## Show backend logs
	docker-compose logs -f backend

frontend-logs: ## Show frontend logs
	docker-compose logs -f frontend

db-logs: ## Show database logs
	docker-compose logs -f db

nginx-logs: ## Show nginx logs
	docker-compose logs -f nginx

# Database commands
db-shell: ## Access database shell
	docker-compose exec db psql -U qc_user -d qc_system

db-reset: ## Reset database (WARNING: destroys data)
	docker-compose down -v
	docker-compose up -d db
	sleep 10
	docker-compose exec backend alembic upgrade head

# Development helpers
dev-setup: ## Setup development environment
	@echo "Setting up development environment..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env file"; fi
	@echo "Please edit .env file with your configuration"

fresh-install: ## Clean install (removes all data)
	docker-compose down -v
	docker system prune -f
	docker-compose up -d --build

# Maintenance
clean: ## Clean up Docker resources
	docker-compose down
	docker system prune -f
	docker volume prune -f

update: ## Update and rebuild services
	@echo "Updating repositories..."
	@if [ -d "Manufacturing-QC-Cross-Check-Backend/.git" ]; then \
		cd Manufacturing-QC-Cross-Check-Backend && git pull origin main; \
	fi
	@if [ -d "Manufacturing-QC-Cross-Check-Frontend/.git" ]; then \
		cd Manufacturing-QC-Cross-Check-Frontend && git pull origin main; \
	fi
	docker-compose up -d --build

# Production deployment
deploy: ## Deploy to production (use with caution)
	@echo "Starting production deployment..."
	chmod +x deploy/deploy.sh
	./deploy/deploy.sh

# Health checks
health: ## Check service health
	@echo "Checking service health..."
	@curl -s http://localhost/health || echo "Backend health check failed"
	@curl -s http://localhost/ > /dev/null && echo "Frontend is accessible" || echo "Frontend check failed"

# Backup
backup: ## Backup database
	@echo "Creating database backup..."
	@mkdir -p backups
	docker-compose exec -T db pg_dump -U qc_user qc_system > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created in backups/ directory"

# Restore from backup
restore: ## Restore database from backup (specify BACKUP_FILE=filename)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Please specify BACKUP_FILE=filename"; \
		echo "Available backups:"; \
		ls -la backups/; \
		exit 1; \
	fi
	@echo "Restoring database from $(BACKUP_FILE)..."
	docker-compose exec -T db psql -U qc_user -d qc_system < $(BACKUP_FILE)

# SSL setup (for production)
ssl-setup: ## Setup SSL certificates with Let's Encrypt
	@echo "Setting up SSL certificates..."
	@echo "Make sure to update nginx.conf with your domain name first"
	docker run --rm -v /etc/letsencrypt:/etc/letsencrypt -v /var/www/certbot:/var/www/certbot certbot/certbot certonly --webroot --webroot-path=/var/www/certbot --email your-email@domain.com --agree-tos --no-eff-email -d your-domain.com

# Monitoring
monitor: ## Show real-time resource usage
	@echo "Monitoring resource usage (Press Ctrl+C to stop)..."
	docker stats

# Quick commands
start: up ## Alias for 'up'
stop: down ## Alias for 'down'
