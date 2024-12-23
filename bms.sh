#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# Check dependencies
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi

# Check Ubuntu version
echo -e "${BLUE}Checking your OS version...${NC}"
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}This node requires at least Ubuntu 22.04${NC}"
    exit 1
fi

# Menu
echo -e "${YELLOW}Select an action:${NC}"
echo -e "${CYAN}1) Install Node${NC}"
echo -e "${CYAN}2) Check Logs${NC}"
echo -e "${CYAN}3) Update Node${NC}"
echo -e "${CYAN}4) Restart Node${NC}"
echo -e "${CYAN}5) Remove Node${NC}"

echo -e "${YELLOW}Enter your choice:${NC} "
read choice

install_or_update() {
    local action=$1
    echo -e "${BLUE}${action} BlockMesh Node...${NC}"

    # Stop existing service if updating
    if [ "$action" = "Updating" ]; then
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        rm -rf target
    fi

    # Install tar if needed
    if ! command -v tar &> /dev/null; then
        sudo apt install tar -y
    fi
    
    # Download manager binary
    wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.443/block-mesh-manager-x86_64-unknown-linux-gnu.tar.gz
    
    # Create directory structure
    mkdir -p target/x86_64-unknown-linux-gnu/release/
    
    # Extract to target directory
    tar -xzvf block-mesh-manager-x86_64-unknown-linux-gnu.tar.gz -C target/x86_64-unknown-linux-gnu/release/
    rm block-mesh-manager-x86_64-unknown-linux-gnu.tar.gz

    # Request credentials
    echo -e "${YELLOW}Enter your BlockMesh email:${NC} "
    read EMAIL
    echo -e "${YELLOW}Enter your BlockMesh password:${NC} "
    read -s PASSWORD

    # Get user info
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    # Create service file
    sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh Manager Service
After=network.target

[Service]
User=$USERNAME
Environment=\"BLOCKMESH_EMAIL=$EMAIL\"
Environment=\"BLOCKMESH_PASSWORD=$PASSWORD\"
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/block-mesh-manager
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT"

    # Start service
    sudo systemctl daemon-reload
    sudo systemctl enable blockmesh
    sudo systemctl start blockmesh

    echo -e "${GREEN}${action} complete and node started!${NC}"
    
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Command to check logs:${NC}" 
    echo "sudo journalctl -u blockmesh -f"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    
    # Show logs
    sudo journalctl -u blockmesh -f
}

case $choice in
    1)
        install_or_update "Installing"
        ;;
    2)
        sudo journalctl -u blockmesh -f
        ;;
    3)
        install_or_update "Updating"
        ;;
    4)
        echo -e "${BLUE}Restarting BlockMesh Node...${NC}"
        sudo systemctl restart blockmesh
        echo -e "${GREEN}Node restarted!${NC}"
        sudo journalctl -u blockmesh -f
        ;;
    5)
        echo -e "${BLUE}Removing BlockMesh Node...${NC}"
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        rm -rf target
        echo -e "${GREEN}Node successfully removed!${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice, exiting...${NC}"
        ;;
esac
