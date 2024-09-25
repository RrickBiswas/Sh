#!/bin/bash

# Script to install and set up a Celestia light node

# 1. Update and upgrade the system
sudo apt-get update && sudo apt-get upgrade -y

# 2. Install essential components
sudo apt install curl tar wget aria2 clang pkg-config libssl-dev jq build-essential \
git make ncdu -y

# 3. Install Go (version 1.23.1)
GO_VERSION="1.23.1"
cd $HOME
wget "https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
rm "go$GO_VERSION.linux-amd64.tar.gz"

# Update profile for Go
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

# 4. Install the Celestia command-line terminal
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/

# Set the version to v0.16.0
git checkout tags/v0.16.0

# Build Celestia
make build && make install && make cel-key

# 5. Wallet setup
echo "Would you like to create a new wallet or import an existing one? (new/import)"
read WALLET_ACTION

if [ "$WALLET_ACTION" == "new" ]; then
  echo "Enter a name for your new Celestia wallet:"
  read WALLET_NAME
  # Create a new wallet
  ./cel-key add $WALLET_NAME --keyring-backend test --node.type light --p2p.network celestia
elif [ "$WALLET_ACTION" == "import" ]; then
  echo "Enter a name for your imported Celestia wallet:"
  read WALLET_NAME
  # Import an existing wallet using the mnemonic
  ./cel-key add $WALLET_NAME --recover --keyring-backend test --node.type light --p2p.network mocha-4
else
  echo "Invalid option selected. Please run the script again and choose 'new' or 'import'."
  exit 1
fi

# 6. Initialize the Celestia node
celestia light init

# 7. Create a systemd service to start the node
sudo tee /etc/systemd/system/celestia.service > /dev/null <<EOF
[Unit]
Description=Celestia Node
After=network.target

[Service]
User=root
ExecStart=/root/celestia-node/build/celestia light start --keyring.accname $WALLET_NAME \
--core.ip consensus.lunaroasis.net
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# 8. Enable and start the Celestia service
sudo systemctl daemon-reload
sudo systemctl enable celestia
sudo systemctl start celestia

# 9. Display the node logs
echo "To view your node's logs, run: journalctl -fu celestia"
