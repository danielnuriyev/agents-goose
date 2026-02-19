#!/bin/bash

# Setup script for Goose with LiteLLM proxy to AWS Bedrock Nova Lite

set -e

echo "Setting up Goose with LiteLLM proxy for AWS Bedrock Nova Lite..."

# Check if AWS credentials exist
if [ ! -f ~/.aws/credentials ]; then
    echo "Error: AWS credentials not found at ~/.aws/credentials"
    echo "Please configure your AWS credentials first:"
    echo "  aws configure"
    echo "Or ensure your credentials are available via environment variables or IAM roles"
    exit 1
fi

# Install LiteLLM if not already installed
if ! command -v litellm &> /dev/null; then
    echo "Installing LiteLLM..."
    pip install litellm boto3
else
    echo "LiteLLM is already installed"
fi

# Create Goose config directory if it doesn't exist
GOOSE_CONFIG_DIR="$HOME/.config/goose"
mkdir -p "$GOOSE_CONFIG_DIR"

# Copy the profile configuration
echo "Configuring Goose profile..."
cp goose_profiles.yaml "$GOOSE_CONFIG_DIR/profiles.yaml"

echo "Setup complete!"
echo ""
echo "To start the LiteLLM proxy:"
echo "  litellm --config litellm_config.yaml"
echo ""
echo "Then start Goose:"
echo "  goose --profile bedrock-nova-lite"
echo ""
echo "Or run the start script:"
echo "  ./start.sh"