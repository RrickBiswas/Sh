#!/bin/bash

# Check if Node.js is installed
if ! command -v node &> /dev/null
then
    echo "Node.js is not installed. Installing Node.js..."
    sudo apt update
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "Node.js is installed."

# Check if npm is installed
if ! command -v npm &> /dev/null
then
    echo "npm is not installed. Installing npm..."
    sudo apt install -y npm
fi

echo "npm is installed."

# Install Hyperlane CLI
echo "Installing Hyperlane CLI..."
npm install -g @hyperlane-xyz/cli

# Check if Hyperlane CLI was installed correctly
if ! command -v hyperlane &> /dev/null
then
    echo "Hyperlane CLI installation failed. Please check for errors."
    exit 1
fi

echo "Hyperlane CLI installed successfully."

# Prompt user for private key and save it in .env file
echo "Please enter your EVM wallet private key (64 characters long, no '0x' prefix): "
read PRIVATE_KEY

# Validate private key format (64 hex characters)
if [[ ! $PRIVATE_KEY =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "Error: Invalid private key format. Please ensure it's a 64-character hex string."
  exit 1
fi

# Prompt user for owner address
echo "Please enter your owner address (your wallet address): "
read OWNER_ADDRESS

# Create or update .env file
echo "Creating .env file..."
echo "HYP_KEY=$PRIVATE_KEY" > .env
source .env
echo "Private key stored and environment sourced."

# Prompt user for token address
echo "Please enter the token contract address (e.g., Brett on Base): "
read TOKEN_ADDRESS

# Initialize Warp Route configuration without prompts
echo "Initializing Warp Route configuration..."
hyperlane warp init -k $PRIVATE_KEY -y \
  --registry=https://github.com/hyperlane-xyz/hyperlane-registry \
  --out=./configs/warp-route-deployment.yaml \
  --from-address=$OWNER_ADDRESS \
  --network=Mainnet \
  --token-address=$TOKEN_ADDRESS

echo "Warp Route configuration initialized."

# Deploy Warp Route Contracts with valid private key
echo "Deploying Warp Route contracts..."
hyperlane warp deploy --key $PRIVATE_KEY --yes

# Output the path to the deployment config
CONFIG_PATH="$HOME/.hyperlane/deployments/warp_routes"
echo "Your token configuration and deployment addresses are stored in: $CONFIG_PATH"

# Guide user for testing in Superbridge UI
echo "You can now test bridging in the Hyperlane sandbox UI."
echo "Visit https://hyperlane.superbridge.app/ and customize the warp route with your config file located at $CONFIG_PATH."

echo "Setup complete! Follow further instructions in the Hyperlane docs for going to production."
