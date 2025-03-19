#!/bin/bash

echo "🚀 Starting LayerEdge Light Node Setup..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Go if not installed
if command_exists go; then
    echo "✅ Go is already installed: $(go version)"
else
    echo "⚡ Installing Go..."
    wget https://go.dev/dl/go1.20.3.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
    source ~/.bashrc
    echo "✅ Go installed successfully!"
fi

# Install Rust if not installed
if command_exists rustc; then
    echo "✅ Rust is already installed: $(rustc --version)"
else
    echo "⚡ Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo "✅ Rust installed successfully!"
fi

# Install Risc0 Toolchain if not installed
if ! command_exists rzup; then
    echo "⚡ Installing Risc0 Toolchain..."
    curl -L https://risczero.com/install | bash && rzup install
    echo "✅ Risc0 Toolchain installed!"
else
    echo "✅ Risc0 Toolchain is already installed."
fi

# Clone the Light Node repository
if [ -d "light-node" ]; then
    echo "✅ Light Node repository already exists. Pulling latest updates..."
    cd light-node && git pull
else
    echo "⚡ Cloning Light Node repository..."
    git clone https://github.com/Layer-Edge/light-node.git
    cd light-node
fi

# Prompt user to enter the private key securely
echo "🔑 Enter your CLI Node Private Key (input will be hidden for security):"
read -s PRIVATE_KEY

# Save environment variables to .env file
echo "⚡ Setting up environment variables..."
cat <<EOF > .env
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
export PRIVATE_KEY=$PRIVATE_KEY
EOF
echo "✅ Environment variables set!"

# Start the Merkle Service
echo "⚡ Starting Merkle Service..."
cd risc0-merkle-service
cargo build && cargo run &

sleep 5 # Give some time for the service to initialize

# Build and run the Light Node
echo "⚡ Building and running Light Node..."
cd ..
go build
./light-node &

echo "🎉 Setup complete! Your LayerEdge Light Node is now running. 🚀"
