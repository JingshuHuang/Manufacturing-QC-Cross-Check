# EC2 Deployment Script for Manufacturing QC Cross-Check System (PowerShell)
# This script helps deploy the application to EC2 from a Windows machine

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2PublicIP,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyFilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "ubuntu"
)

# Colors for output
function Write-Status {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️ $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if SSH is available
    try {
        Get-Command ssh -ErrorAction Stop | Out-Null
        Write-Status "SSH is available"
    }
    catch {
        Write-Error "SSH is not available. Please install OpenSSH or use WSL."
        exit 1
    }
    
    # Check if key file exists
    if (-not (Test-Path $KeyFilePath)) {
        Write-Error "Key file not found: $KeyFilePath"
        exit 1
    }
    
    Write-Status "Prerequisites check completed"
}

# Function to test SSH connection
function Test-SSHConnection {
    Write-Info "Testing SSH connection to $EC2PublicIP..."
    
    $testCommand = "ssh -i `"$KeyFilePath`" -o ConnectTimeout=10 -o StrictHostKeyChecking=no $Username@$EC2PublicIP 'echo Connection successful'"
    
    try {
        $result = Invoke-Expression $testCommand
        if ($result -match "Connection successful") {
            Write-Status "SSH connection successful"
            return $true
        }
        else {
            Write-Error "SSH connection failed"
            return $false
        }
    }
    catch {
        Write-Error "SSH connection failed: $_"
        return $false
    }
}

# Function to execute command on EC2
function Invoke-EC2Command {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Info $Description
    
    $sshCommand = "ssh -i `"$KeyFilePath`" -o StrictHostKeyChecking=no $Username@$EC2PublicIP '$Command'"
    
    try {
        $result = Invoke-Expression $sshCommand
        Write-Status "$Description completed"
        return $result
    }
    catch {
        Write-Error "$Description failed: $_"
        throw
    }
}

# Function to copy deployment script to EC2
function Copy-DeploymentScript {
    Write-Info "Copying deployment script to EC2..."
    
    $localScriptPath = Join-Path $PSScriptRoot "ec2-deploy.sh"
    
    if (-not (Test-Path $localScriptPath)) {
        Write-Error "Deployment script not found: $localScriptPath"
        exit 1
    }
    
    # Copy script to EC2
    $scpCommand = "scp -i `"$KeyFilePath`" -o StrictHostKeyChecking=no `"$localScriptPath`" $Username@${EC2PublicIP}:~/ec2-deploy.sh"
    
    try {
        Invoke-Expression $scpCommand
        Write-Status "Deployment script copied to EC2"
    }
    catch {
        Write-Error "Failed to copy deployment script: $_"
        exit 1
    }
}

# Function to run deployment on EC2
function Start-Deployment {
    Write-Info "Starting deployment on EC2..."
    
    # Make script executable and run it
    $deployCommand = @"
chmod +x ~/ec2-deploy.sh && ~/ec2-deploy.sh
"@
    
    try {
        Invoke-EC2Command -Command $deployCommand -Description "Running deployment script"
        Write-Status "Deployment completed successfully"
    }
    catch {
        Write-Error "Deployment failed"
        throw
    }
}

# Function to display deployment information
function Show-DeploymentInfo {
    Write-Info "Getting deployment information..."
    
    # Get application status
    $statusCommand = "cd /opt/manufacturing-qc && docker-compose ps"
    $status = Invoke-EC2Command -Command $statusCommand -Description "Checking application status"
    
    Write-Host ""
    Write-Status "🎉 Deployment Information"
    Write-Host "=========================="
    Write-Host ""
    Write-Host "📍 Access URLs:"
    Write-Host "🌐 Application: http://$EC2PublicIP"
    Write-Host "🔧 Backend API: http://$EC2PublicIP/api"
    Write-Host "📚 API Documentation: http://$EC2PublicIP/docs"
    Write-Host "❤️ Health Check: http://$EC2PublicIP/health"
    Write-Host ""
    Write-Host "🐳 Service Status:"
    Write-Host $status
    Write-Host ""
    Write-Host "🛠️ Management Commands (run via SSH):"
    Write-Host "📊 Check status: docker-compose ps"
    Write-Host "📋 View logs: docker-compose logs"
    Write-Host "🔄 Restart: docker-compose restart"
    Write-Host ""
}

# Function to open browser
function Open-Application {
    $url = "http://$EC2PublicIP"
    Write-Info "Opening application in browser: $url"
    
    try {
        Start-Process $url
        Write-Status "Browser opened"
    }
    catch {
        Write-Warning "Could not open browser automatically. Please navigate to: $url"
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-Info "🚀 Manufacturing QC EC2 Deployment (PowerShell)"
    Write-Host "==============================================="
    Write-Host ""
    Write-Host "Target EC2: $EC2PublicIP"
    Write-Host "Key File: $KeyFilePath"
    Write-Host "Username: $Username"
    Write-Host ""
    
    try {
        Test-Prerequisites
        
        if (-not (Test-SSHConnection)) {
            Write-Error "Cannot connect to EC2 instance. Please check:"
            Write-Host "1. EC2 instance is running"
            Write-Host "2. Security group allows SSH (port 22) from your IP"
            Write-Host "3. Key file path is correct"
            Write-Host "4. Public IP is correct"
            exit 1
        }
        
        Copy-DeploymentScript
        Start-Deployment
        Show-DeploymentInfo
        
        Write-Host ""
        Write-Status "✨ Deployment completed successfully!"
        Write-Host ""
        
        # Ask if user wants to open browser
        $openBrowser = Read-Host "Would you like to open the application in your browser? (y/n)"
        if ($openBrowser -eq 'y' -or $openBrowser -eq 'Y' -or $openBrowser -eq 'yes') {
            Open-Application
        }
        
    }
    catch {
        Write-Error "Deployment failed: $_"
        Write-Host ""
        Write-Info "Troubleshooting steps:"
        Write-Host "1. Check EC2 instance status in AWS console"
        Write-Host "2. Verify security group settings"
        Write-Host "3. Confirm SSH key permissions"
        Write-Host "4. Check EC2 instance logs"
        exit 1
    }
}

# Help function
function Show-Help {
    Write-Host ""
    Write-Host "Manufacturing QC EC2 Deployment Script"
    Write-Host "======================================"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\ec2-deploy.ps1 -EC2PublicIP <IP> -KeyFilePath <path> [-Username <user>]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -EC2PublicIP   : Public IP address of your EC2 instance (required)"
    Write-Host "  -KeyFilePath   : Path to your EC2 key pair file (.pem) (required)"
    Write-Host "  -Username      : SSH username (default: ubuntu)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\ec2-deploy.ps1 -EC2PublicIP 54.123.45.67 -KeyFilePath C:\keys\my-key.pem"
    Write-Host "  .\ec2-deploy.ps1 -EC2PublicIP 54.123.45.67 -KeyFilePath .\my-key.pem -Username ec2-user"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "1. EC2 instance running Ubuntu 22.04 LTS"
    Write-Host "2. Security group allowing SSH (22), HTTP (80), HTTPS (443)"
    Write-Host "3. SSH client installed (OpenSSH)"
    Write-Host "4. Valid EC2 key pair file"
    Write-Host ""
}

# Check if help is requested
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "-h") {
    Show-Help
    exit 0
}

# Validate parameters
if (-not $EC2PublicIP -or -not $KeyFilePath) {
    Write-Error "Missing required parameters"
    Show-Help
    exit 1
}

# Run main function
Main
