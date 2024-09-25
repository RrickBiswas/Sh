#!/bin/bash

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        
        # Install dependencies for Docker
        sudo apt install -y ca-certificates curl gnupg lsb-release
        
        # Add Docker’s official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Set up the stable repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update the package index and install Docker
        sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
        
        # Add current user to the Docker group
        sudo usermod -aG docker $USER
        
        # Activate new group settings
        newgrp docker
        
        echo "Docker installed successfully!"
    else
        echo "Docker is already installed."
    fi
}

# Check for Docker installation
check_docker

# Set variables for network and node type
NETWORK="mocha"
NODE_TYPE="light"
RPC_URL="consensus-full-mocha-4.celestia-mocha.com"

# Print configuration for user confirmation
echo "Running Celestia $NODE_TYPE node on the $NETWORK network."
echo "Using RPC URL: $RPC_URL"
echo

# Ask if the user wants to create a new wallet or import an existing one
echo "Would you like to create a new wallet or import an existing one? (new/import)"
read WALLET_CHOICE

# Run the Docker container interactively for wallet creation/import
docker run -it --entrypoint /bin/bash ghcr.io/celestiaorg/celestia-node:v0.16.0 -c "\
    cd /root/.celestia-node/ && \
    if [ \"$WALLET_CHOICE\" == \"new\" ]; then
        echo 'Creating a new wallet...'
        echo 'Enter a name for your new wallet:'
        read WALLET_NAME
        ./cel-key add \$WALLET_NAME --keyring-backend test --node.type light --p2p.network $NETWORK
    elif [ \"$WALLET_CHOICE\" == \"import\" ]; then
        echo 'Importing an existing wallet...'
        echo 'Enter a name for your imported wallet:'
        read WALLET_NAME
        ./cel-key add \$WALLET_NAME --recover --keyring-backend test --node.type light --p2p.network $NETWORK
    else
        echo 'Invalid option. Exiting...'
        exit 1
    fi
"

# Start the Celestia light node after wallet creation/import
docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
  ghcr.io/celestiaorg/celestia-node:v0.16.0 \
  celestia $NODE_TYPE start --core.ip $RPC_URL --p2p.network $NETWORK

# Notify the user
echo "Celestia $NODE_TYPE node is starting on the $NETWORK network using Docker..."
