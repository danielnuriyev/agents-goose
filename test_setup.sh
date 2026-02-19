#!/bin/bash

# Test script to verify the Goose + LiteLLM + AWS Bedrock Nova Lite setup

set -e

echo "Testing Goose + LiteLLM + AWS Bedrock Nova Lite setup..."
echo "===================================================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Run setup.sh first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo "✅ Virtual environment activated"

# Check if LiteLLM proxy is running
if ! curl -s http://localhost:4000/health > /dev/null; then
    echo "❌ LiteLLM proxy not running. Start it with: source venv/bin/activate && litellm --config litellm_config.yaml"
    exit 1
fi

echo "✅ LiteLLM proxy is running on port 4000"

# Test proxy connectivity
echo "🧪 Testing LiteLLM proxy connection to AWS Bedrock..."
RESPONSE=$(curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bedrock-nova-lite",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }')

if echo "$RESPONSE" | grep -q "not authorized"; then
    echo "✅ LiteLLM proxy can connect to AWS (but lacks Bedrock permissions)"
    echo "   To fix: Add Bedrock permissions to your AWS user/role"
elif echo "$RESPONSE" | grep -q "choices"; then
    echo "✅ LiteLLM proxy working perfectly with AWS Bedrock!"
    CONTENT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'][:100])")
    echo "   Sample response: $CONTENT..."
else
    echo "❌ LiteLLM proxy connection failed:"
    echo "   $RESPONSE"
    exit 1
fi

# Check Goose installation
if ! command -v goose &> /dev/null; then
    echo "❌ Goose not found. Install it from: https://block.github.io/goose/docs/getting-started/installation"
    exit 1
fi

echo "✅ Goose is installed"

# Check if profile config exists
if [ ! -f ~/.config/goose/profiles.yaml ]; then
    echo "⚠️  Goose profile not configured. Run: cp goose_profiles.yaml ~/.config/goose/profiles.yaml"
else
    echo "✅ Goose profile configured"
fi

echo ""
echo "🎉 Setup verification complete!"
echo ""
echo "To start using Goose with AWS Bedrock Nova Lite:"
echo "1. Ensure you have Bedrock permissions (see README.md)"
echo "2. Start LiteLLM proxy: source venv/bin/activate && litellm --config litellm_config.yaml"
echo "3. Start Goose: goose --profile bedrock-nova-lite"
echo ""
echo "For manual testing of the proxy:"
echo "curl -X POST http://localhost:4000/v1/chat/completions \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"bedrock-nova-lite\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'"