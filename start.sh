#!/bin/bash

# Start script for Goose with LiteLLM proxy

set -e

echo "Starting LiteLLM proxy for AWS Bedrock Nova Lite..."

# Check if LiteLLM proxy is already running
if lsof -i :4000 &> /dev/null; then
    echo "LiteLLM proxy appears to be running on port 4000"
else
    echo "Starting LiteLLM proxy..."
    litellm --config litellm_config.yaml &
    LITELLM_PID=$!

    # Wait a moment for the proxy to start
    sleep 3

    echo "LiteLLM proxy started with PID: $LITELLM_PID"
fi

echo "Starting Goose with bedrock-nova-lite profile..."
goose --profile bedrock-nova-lite