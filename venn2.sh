#!/bin/bash

# venn-deploy.sh
# Full working version for GitHub Codespaces

set -e  # Exit on error

# ASCII Header
echo "_____________________________________________________________"
echo "|   ___  _____  _  _   _    ___  _  _  ___  _  _  ___  ___  |"
echo "|  |_ _||_   _|| || | / |  / __|| || || __|| \| || __|| _ \ |"
echo "|   | |   | |  | __ | | | | (_ || __ || _| | .  || _| |   / |"
echo "|  |___|  |_|  |_||_| |_|  \___||_||_||___||_|\_||___||_|_\ |"
echo "|___________________________________________________________|"
echo "           Venn-Protected Contract Deployment v1.2           "

# ------------------------------------------------------------------------------
# Secure Input Handling
# ------------------------------------------------------------------------------
echo -e "\n🔐 Security Checkpoint 🔐"
read -sp "Enter Ethereum PRIVATE KEY (0x...): " ETH_KEY
echo
read -sp "Enter Venn PRIVATE KEY: " VENN_KEY
echo

# ------------------------------------------------------------------------------
# Project Initialization
# ------------------------------------------------------------------------------
echo -e "\n🚀 Initializing project..."
rm -rf .gitignore sample-projects  # Clean existing files
npm init -y > /dev/null
mkdir -p contracts scripts

# ------------------------------------------------------------------------------
# Dependency Installation
# ------------------------------------------------------------------------------
echo -e "\n📦 Installing dependencies..."
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv > /dev/null
npm install -g @vennbuild/cli > /dev/null

# ------------------------------------------------------------------------------
# Hardhat Setup with Fixed Input Handling
# ------------------------------------------------------------------------------
echo -e "\n⚙️ Setting up Hardhat..."
{
  printf "y\ny\nn\n" | npx hardhat init > hardhat-init.log 2>&1
  
  if grep -qi "error" hardhat-init.log; then
    echo "❌ Hardhat setup failed! Check hardhat-init.log"
    exit 1
  fi
  rm hardhat-init.log
}

# ------------------------------------------------------------------------------
# Contract Creation
# ------------------------------------------------------------------------------
echo -e "\n📄 Creating smart contract..."
cat > contracts/MyContract.sol <<'EOF'
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
# Venn Integration
# ------------------------------------------------------------------------------
echo -e "\n🛡️ Applying Venn Protection..."
venn fw integ -d contracts > venn-integ.log 2>&1 || {
  echo "❌ Venn integration failed! Check venn-integ.log"
  exit 1
}

# ------------------------------------------------------------------------------
# Configuration Files
# ------------------------------------------------------------------------------
echo -e "\n🔧 Generating config files..."
cat > hardhat.config.js <<EOF
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    holesky: {
      url: "https://ethereum-holesky.publicnode.com",
      accounts: [process.env.ETH_KEY]
    }
  }
};
EOF

echo "ETH_KEY=$ETH_KEY" > .env
echo "VENN_KEY=$VENN_KEY" >> .env
echo ".env" >> .gitignore

# ------------------------------------------------------------------------------
# Deployment Automation
# ------------------------------------------------------------------------------
echo -e "\n🚀 Creating deploy script..."
cat > scripts/deploy.js <<'EOF'
const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.deployContract("MyContract");
  await contract.waitForDeployment();
  console.log("CONTRACT_ADDRESS=%s", contract.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOF

# ------------------------------------------------------------------------------
# Contract Deployment
# ------------------------------------------------------------------------------
echo -e "\n🌐 Deploying to Holesky..."
DEPLOY_OUTPUT=$(npx hardhat run --network holesky scripts/deploy.js)
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | awk -F= '/CONTRACT_ADDRESS/ {print $2}')
echo "✅ Contract deployed: $CONTRACT_ADDRESS"

# ------------------------------------------------------------------------------
# Venn Registration
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

VENN_PRIVATE_KEY=$VENN_KEY venn enable --holesky > venn-register.log 2>&1 || {
  echo "❌ Venn registration failed! Check venn-register.log"
  exit 1
}

# ------------------------------------------------------------------------------
# Finalization
# ------------------------------------------------------------------------------
echo -e "\n✅ Deployment Complete!"
echo "_____________________________________________________________"
echo "Contract Address: $CONTRACT_ADDRESS"
echo "Venn Policy ID:   $(grep 'Policy ID' venn-register.log | awk '{print $3}')"
echo "GitHub Setup:     Complete"
echo "_____________________________________________________________"

# Security cleanup
unset ETH_KEY VENN_KEY