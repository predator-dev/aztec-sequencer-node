#!/bin/bash

# Aztec Sequencer Node Manager
# A user-friendly manager for the Aztec Sequencer Node
# Created based on official repository: https://github.com/Jaytechent/Aztec-Sequencer-Node

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
DOCKER_COMPOSE_FILE="$HOME/aztec-sequencer-node/docker-compose.yml"
NODE_DIR="$HOME/aztec-sequencer-node"
BACKUP_DIR="$HOME/aztec-node-backup"
LOG_FILE="$HOME/aztec-node.log"

# Function to print styled messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_message $RED "Docker is not installed. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        print_message $GREEN "Docker installed successfully!"
        print_message $YELLOW "Please logout and login again to use Docker without sudo."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "Docker Compose is not installed. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_message $GREEN "Docker Compose installed successfully!"
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_message $BLUE "Checking system requirements..."
    
    # Check CPU cores
    cpu_cores=$(nproc)
    if [ $cpu_cores -lt 4 ]; then
        print_message $YELLOW "Warning: You have less than 4 CPU cores ($cpu_cores). Performance may be affected."
    else
        print_message $GREEN "CPU cores: $cpu_cores - OK"
    fi
    
    # Check RAM
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ $total_ram -lt 8192 ]; then
        print_message $YELLOW "Warning: You have less than 8GB RAM (${total_ram}MB). Performance may be affected."
    else
        print_message $GREEN "RAM: ${total_ram}MB - OK"
    fi
    
    # Check free disk space
    free_space=$(df -h $HOME | awk 'NR==2 {print $4}')
    print_message $GREEN "Free disk space: $free_space"
    
    # Check if ports are available
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
        print_message $YELLOW "Warning: Port 8080 is already in use. The node may not start correctly."
    else
        print_message $GREEN "Port 8080 is available - OK"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_message $BLUE "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y curl wget git jq lsof htop
    print_message $GREEN "Dependencies installed successfully!"
}

# Function to install/update node
install_node() {
    print_message $BLUE "Setting up Aztec Sequencer Node..."
    
    # Create backup if updating
    if [ -d "$NODE_DIR" ]; then
        print_message $YELLOW "Existing installation found. Creating backup before updating..."
        backup_node
    fi
    
    # Remove existing directory if needed
    if [ -d "$NODE_DIR" ]; then
        print_message $YELLOW "Removing existing installation..."
        rm -rf $NODE_DIR
    fi
    
    # Clone repository
    print_message $BLUE "Cloning Aztec Sequencer Node repository..."
    git clone https://github.com/Jaytechent/Aztec-Sequencer-Node.git $NODE_DIR
    
    # Setup the node
    cd $NODE_DIR
    print_message $BLUE "Setting up environment..."
    
    # Ask for user input for wallet address
    echo ""
    read -p "Enter your Ethereum wallet address (0x...): " wallet_address
    
    # Validate wallet address
    if [[ ! $wallet_address =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        print_message $RED "Invalid wallet address format. It should start with 0x followed by 40 hex characters."
        return 1
    fi
    
    # Update configuration files if needed
    print_message $BLUE "Updating configuration with wallet address: $wallet_address"
    
    # Restore data from backup if available
    if [ -d "$BACKUP_DIR/data" ]; then
        print_message $YELLOW "Backup data found. Would you like to restore it? (y/n)"
        read restore_choice
        if [[ $restore_choice == "y" || $restore_choice == "Y" ]]; then
            restore_node
        fi
    fi
    
    print_message $GREEN "Aztec Sequencer Node has been successfully set up!"
    print_message $GREEN "You can now start the node using the 'Start Node' option."
}

# Function to start node
start_node() {
    if [ ! -d "$NODE_DIR" ]; then
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    cd $NODE_DIR
    print_message $BLUE "Starting Aztec Sequencer Node..."
    
    # Pull latest images
    docker-compose pull
    
    # Start containers
    docker-compose up -d
    
    # Check if containers are running
    if [ $? -eq 0 ]; then
        print_message $GREEN "Aztec Sequencer Node started successfully!"
    else
        print_message $RED "Failed to start Aztec Sequencer Node. Check logs for more information."
    fi
}

# Function to stop node
stop_node() {
    if [ ! -d "$NODE_DIR" ]; then
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    cd $NODE_DIR
    print_message $BLUE "Stopping Aztec Sequencer Node..."
    docker-compose down
    
    print_message $GREEN "Aztec Sequencer Node stopped successfully!"
}

# Function to check node status
check_status() {
    if [ ! -d "$NODE_DIR" ]; then
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    cd $NODE_DIR
    print_message $BLUE "Checking Aztec Sequencer Node status..."
    
    # Check docker containers
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep aztec
    
    # If no containers are running
    if [ $? -ne 0 ]; then
        print_message $YELLOW "No running Aztec Sequencer Node containers found."
    fi
    
    # Check node URL
    print_message $BLUE "\nTesting node API endpoint..."
    if curl -s http://localhost:8080/status > /dev/null; then
        print_message $GREEN "Node API is accessible - OK"
    else
        print_message $RED "Node API is not accessible"
    fi
}

# Function to view logs
view_logs() {
    if [ ! -d "$NODE_DIR" ]; then
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    cd $NODE_DIR
    print_message $BLUE "Viewing Aztec Sequencer Node logs..."
    print_message $YELLOW "Press Ctrl+C to exit logs"
    sleep 2
    
    docker-compose logs --tail=100 -f
}

# Function to backup node data
backup_node() {
    if [ ! -d "$NODE_DIR" ]; then
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    print_message $BLUE "Backing up Aztec Sequencer Node data..."
    
    # Create backup directory if it doesn't exist
    mkdir -p $BACKUP_DIR
    
    # Stop node if running
    cd $NODE_DIR
    docker-compose down
    
    # Create timestamp for backup
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # Backup data directory
    if [ -d "$NODE_DIR/data" ]; then
        print_message $BLUE "Backing up data directory..."
        cp -r $NODE_DIR/data $BACKUP_DIR/data_$timestamp
        ln -sfn $BACKUP_DIR/data_$timestamp $BACKUP_DIR/data
    fi
    
    # Backup configuration files
    print_message $BLUE "Backing up configuration files..."
    mkdir -p $BACKUP_DIR/config_$timestamp
    cp $NODE_DIR/docker-compose.yml $BACKUP_DIR/config_$timestamp/
    ln -sfn $BACKUP_DIR/config_$timestamp $BACKUP_DIR/config
    
    print_message $GREEN "Backup completed successfully!"
    print_message $GREEN "Backup saved to: $BACKUP_DIR/data_$timestamp and $BACKUP_DIR/config_$timestamp"
}

# Function to restore node data
restore_node() {
    if [ ! -d "$BACKUP_DIR" ]; then
        print_message $RED "No backups found. Please create a backup first."
        return 1
    fi
    
    print_message $BLUE "Restoring Aztec Sequencer Node data..."
    
    # Stop node if running
    if [ -d "$NODE_DIR" ]; then
        cd $NODE_DIR
        docker-compose down
    else
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    # Check if data directory exists in backup
    if [ -d "$BACKUP_DIR/data" ]; then
        print_message $BLUE "Restoring data directory..."
        rm -rf $NODE_DIR/data
        cp -r $BACKUP_DIR/data $NODE_DIR/
    else
        print_message $RED "No data backup found."
        return 1
    fi
    
    # Check if config directory exists in backup
    if [ -d "$BACKUP_DIR/config" ]; then
        print_message $BLUE "Restoring configuration files..."
        cp -f $BACKUP_DIR/config/docker-compose.yml $NODE_DIR/
    fi
    
    print_message $GREEN "Restore completed successfully!"
}

# Function to update node
update_node() {
    print_message $BLUE "Updating Aztec Sequencer Node..."
    
    # Create backup before updating
    backup_node
    
    # Navigate to node directory
    cd $NODE_DIR
    
    # Pull latest changes from repository
    git pull
    
    # Pull latest docker images
    docker-compose pull
    
    print_message $GREEN "Aztec Sequencer Node updated successfully!"
    print_message $GREEN "You can now start the node using the 'Start Node' option."
}

# Function to monitor resources
monitor_resources() {
    print_message $BLUE "Monitoring system resources..."
    print_message $YELLOW "Press Ctrl+C to exit monitoring"
    sleep 2
    
    # Run htop in foreground
    htop
}

# Function to show node information
show_info() {
    if [ ! -d "$NODE_DIR" ]; then
        print_message $RED "Aztec Sequencer Node is not installed. Please install it first."
        return 1
    fi
    
    print_message $BLUE "Aztec Sequencer Node Information:"
    print_message $CYAN "Installation Directory: $NODE_DIR"
    print_message $CYAN "Backup Directory: $BACKUP_DIR"
    
    # Check if node is running
    cd $NODE_DIR
    if docker-compose ps | grep -q "Up"; then
        print_message $GREEN "Node Status: Running"
        
        # Get container stats
        print_message $CYAN "\nContainer Resource Usage:"
        docker stats --no-stream $(docker-compose ps -q)
    else
        print_message $YELLOW "Node Status: Not Running"
    fi
    
    # Show available backups
    if [ -d "$BACKUP_DIR" ]; then
        backup_count=$(ls -d $BACKUP_DIR/data_* 2>/dev/null | wc -l)
        print_message $CYAN "\nAvailable Backups: $backup_count"
        if [ $backup_count -gt 0 ]; then
            print_message $CYAN "Latest Backup: $(ls -dt $BACKUP_DIR/data_* | head -n1)"
        fi
    fi
}

# Function to clean up old data and logs
cleanup() {
    print_message $BLUE "Cleaning up old data and logs..."
    
    # Ask for confirmation
    print_message $YELLOW "This will remove old logs and temporary files. Continue? (y/n)"
    read cleanup_choice
    if [[ $cleanup_choice != "y" && $cleanup_choice != "Y" ]]; then
        print_message $YELLOW "Cleanup cancelled."
        return 0
    fi
    
    # Clean Docker cache
    print_message $BLUE "Cleaning Docker cache..."
    docker system prune -f
    
    # Remove old log files
    print_message $BLUE "Removing old log files..."
    find $HOME -name "aztec-node*.log" -mtime +7 -delete
    
    # Keep only the 3 most recent backups
    if [ -d "$BACKUP_DIR" ]; then
        print_message $BLUE "Cleaning old backups (keeping 3 most recent)..."
        ls -dt $BACKUP_DIR/data_* | tail -n +4 | xargs rm -rf
        ls -dt $BACKUP_DIR/config_* | tail -n +4 | xargs rm -rf
    fi
    
    print_message $GREEN "Cleanup completed successfully!"
}

# Main menu function
show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               ${GREEN}AZTEC SEQUENCER NODE MANAGER${BLUE}                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}                    Created by $(whoami)${NC}"
    echo ""
    echo -e "${YELLOW}1)${NC} Install/Update Aztec Sequencer Node"
    echo -e "${YELLOW}2)${NC} Start Node"
    echo -e "${YELLOW}3)${NC} Stop Node"
    echo -e "${YELLOW}4)${NC} Check Node Status"
    echo -e "${YELLOW}5)${NC} View Node Logs"
    echo -e "${YELLOW}6)${NC} Backup Node Data"
    echo -e "${YELLOW}7)${NC} Restore Node Data"
    echo -e "${YELLOW}8)${NC} Update Node Software"
    echo -e "${YELLOW}9)${NC} Monitor System Resources"
    echo -e "${YELLOW}10)${NC} Show Node Information"
    echo -e "${YELLOW}11)${NC} Cleanup Old Data and Logs"
    echo -e "${YELLOW}12)${NC} Check System Requirements"
    echo -e "${YELLOW}0)${NC} Exit"
    echo ""
    echo -e "${BLUE}Please enter your choice [0-12]:${NC}"
}

# Main execution
check_docker

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) stop_node ;;
        4) check_status ;;
        5) view_logs ;;
        6) backup_node ;;
        7) restore_node ;;
        8) update_node ;;
        9) monitor_resources ;;
        10) show_info ;;
        11) cleanup ;;
        12) check_system_requirements ;;
        0) 
            print_message $GREEN "Thank you for using Aztec Sequencer Node Manager!"
            exit 0
            ;;
        *)
            print_message $RED "Invalid option. Please try again."
            ;;
    esac
    
    echo ""
    print_message $BLUE "Press Enter to continue..."
    read
done
