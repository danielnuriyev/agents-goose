#!/bin/bash

# Start script for Goose Task Server and LiteLLM proxy
# This script activates the virtual environment and starts both services

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Goose Task Server services..."

# Kill any existing processes on the required ports
echo "Checking for existing processes on ports 4321 and 8765..."
lsof -ti:4321,8765 | xargs kill -9 2>/dev/null || true
sleep 1

# Activate virtual environment
echo "Activating virtual environment..."
source "${SCRIPT_DIR}/.venv/bin/activate"

# Start LiteLLM proxy in background
echo "Starting LiteLLM proxy on port 4321..."
litellm --config "${SCRIPT_DIR}/litellm_config.yaml" --port 4321 &
LITELLM_PID=$!

# Wait a moment for LiteLLM to start
sleep 3

# Start Goose task server in background
echo "Starting Goose task server on port 8765..."
python "${SCRIPT_DIR}/goose_server.py" &
GOOSE_PID=$!

# Wait a moment for services to fully start
sleep 2

echo ""
echo "Services started successfully!"
echo "  LiteLLM proxy (PID: ${LITELLM_PID}): http://localhost:4321"
echo "  Goose server (PID: ${GOOSE_PID}): http://localhost:8765"
echo ""
echo "To stop services:"
echo "  kill ${LITELLM_PID} ${GOOSE_PID}"
echo "  # or: lsof -ti:4321,8765 | xargs kill -9"
echo ""
echo "Services are running in the background. You can close this terminal."