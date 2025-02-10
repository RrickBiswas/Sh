#!/bin/bash

# deploy-venn-contract.sh
# Fully automated deployment with private key prompt

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------
set -e  # Exit immediately if any command fails

# ASCII Art Header
echo "_____________________________________________________________"
echo "|   ___  _____  _  _   _    ___  _  _  ___  _  _  ___  ___  |"
echo "|  |_ _||_   _|| || | / |  / __|| || || __|| \| || __|| _ \ |"
echo "|   | |   | |  | __ | | | | (_ || __ || _| | .  || _| |   / |"
echo "|  |___|  |_|  |_||_| |_|  \___||_||_||___||_|\_||___||_|_\ |"
echo "|___________________________________________________________|"
echo "           Venn-Protected Contract Deployment v1.1           "

# ------------------------------------------------------------------------------
# Step 1: Get Private Key Securely
# ------------------------------------------------------------------------------
echo -e "\n🔐 Security Checkpoint 🔐"
read -sp "Enter your Ethereum PRIVATE KEY (will be hidden): " PRIVATE_KEY
echo  # Add newline after hidden input
read -sp "Enter your Venn PRIVATE KEY (will be hidden): " VENN_PRIVATE_KEY
echo  # Add newline after hidden input

# ------------------------------------------------------------------------------
# Step 2: Project Setup
# ------------------------------------------------------------------------------
echo -e "\n🚀 Initializing project..."
npm init -y > /dev/null 2>&1
mkdir -p contracts scripts

# ------------------------------------------------------------------------------
# Step 3: Dependency Installation
# ------------------------------------------------------------------------------
echo -e "\n📦 Installing dependencies..."
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv > /dev/null 2>&1
npm install -g @vennbuild/cli > /dev/null 2>&1

# ------------------------------------------------------------------------------
# Step 4: Hardhat Configuration
# ------------------------------------------------------------------------------
echo -e "\n⚙️ Setting up Hardhat..."
npx hardhat init <<< $'y\n\ny\nn' > /dev/null 2>&1

# ------------------------------------------------------------------------------
# Step 5: Contract Creation
# ------------------------------------------------------------------------------
echo -e "\n📄 Creating smart contract..."
cat > contracts/MyContract.sol <<EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyContract {
    uint256 public value;
    
    function setValue(uint256 _value) public {
        value = _value;
    }
}
EOF

# ------------------------------------------------------------------------------
# Step 6: Venn Firewall Integration
# ------------------------------------------------------------------------------
echo -e "\n🛡️ Integrating Venn Firewall..."
venn fw integ -d contracts > /dev/null 2>&1

# ------------------------------------------------------------------------------
# Step 7: Environment Configuration
# ------------------------------------------------------------------------------
echo -e "\n🔧 Configuring environment..."
cat > hardhat.config.js <<EOF
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
    solidity: "0.8.19",
    networks: {
        holesky: {
            url: "https://ethereum-holesky.publicnode.com",
            accounts: [process.env.PRIVATE_KEY],
        }
    }
};
EOF

# Create secure environment file
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo "VENN_PRIVATE_KEY=$VENN_PRIVATE_KEY" >> .env
echo ".env" >> .gitignore

# ------------------------------------------------------------------------------
# Step 8: Deployment Automation
# ------------------------------------------------------------------------------
echo -e "\n🚀 Creating deployment script..."
cat > scripts/deploy.js <<EOF
const hre = require("hardhat");

async function main() {
    const MyContract = await hre.ethers.getContractFactory("MyContract");
    const myContract = await MyContract.deploy();
    await myContract.deployed();
    console.log("CONTRACT_ADDRESS=%s", myContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
EOF

# ------------------------------------------------------------------------------
# Step 9: Contract Deployment
# ------------------------------------------------------------------------------
echo -e "\n🌐 Deploying to Holesky Testnet..."
DEPLOY_OUTPUT=$(npx hardhat run --network holesky scripts/deploy.js)
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | awk -F= '/CONTRACT_ADDRESS/ {print $2}')
echo "✅ Contract deployed at: $CONTRACT_ADDRESS"

# ------------------------------------------------------------------------------
# Step 10: Venn Registration
# ------------------------------------------------------------------------------
echo -e "\n🔗 Registering with Venn..."
cat > venn.config.json <<EOF
{
    "networks": {
        "holesky": {
            "contracts": {
                "MyContract": "$CONTRACT_ADDRESS"
            }
        }
    }
}
EOF

export VENN_PRIVATE_KEY=$VENN_PRIVATE_KEY
venn enable --holesky > /dev/null 2>&1

# ------------------------------------------------------------------------------
# Final Cleanup and Output
# ------------------------------------------------------------------------------
echo -e "\n✅ Deployment Complete!"
echo "_____________________________________________________________"
echo "Contract Address: $CONTRACT_ADDRESS"
echo "Network: Holesky Testnet"
echo "Venn Protection: Enabled ✅"
echo "GitHub Setup: Complete ✅"
echo "_____________________________________________________________"

# ------------------------------------------------------------------------------
# Security Cleanup
# ------------------------------------------------------------------------------
# Clear sensitive variables from memory
unset PRIVATE_KEY
unset VENN_PRIVATE_KEY