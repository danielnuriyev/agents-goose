# Goose with AWS Bedrock Nova Lite via LiteLLM Proxy

This setup configures [Block Goose](https://block.github.io/goose/) to use AWS Bedrock Nova Lite as its LLM through a LiteLLM proxy. This provides a standardized OpenAI-compatible API interface to Goose while using Amazon's Nova Lite model.

## Prerequisites

1. **AWS Account** with access to Amazon Bedrock
2. **AWS Credentials** configured locally (`~/.aws/credentials`)
3. **Python 3.8+** installed
4. **Goose CLI** installed (see installation below)

## Quick Start

1. **Clone or copy this configuration:**
   ```bash
   cd agents-goose
   ```

2. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

3. **Start Goose with the Bedrock Nova Lite profile:**
   ```bash
   ./start.sh
   ```

That's it! Goose will now use AWS Bedrock Nova Lite through the LiteLLM proxy.

## Manual Setup Instructions

If you prefer to set things up manually, follow these steps:

### 1. Install Dependencies

**Install LiteLLM and boto3:**
```bash
pip install litellm boto3
```

**Install Goose CLI:**
```bash
# macOS/Linux/Windows
curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | bash

# Or using Homebrew (macOS)
brew install --cask block-goose
```

### 2. Configure AWS Credentials

Ensure your AWS credentials are available. LiteLLM uses boto3, which automatically looks for credentials in:

- `~/.aws/credentials` file
- Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION_NAME`)
- IAM roles (if running on EC2/ECS/EKS)

Configure credentials if needed:
```bash
aws configure
```

### 3. Configure LiteLLM Proxy

The `litellm_config.yaml` file contains the model configuration:

```yaml
model_list:
  - model_name: bedrock-nova-lite
    litellm_params:
      model: bedrock/amazon.nova-lite-v1:0
      aws_region_name: us-east-1  # Change to your preferred region
```

**Supported AWS Regions for Nova Lite:**
- us-east-1 (N. Virginia)
- us-west-2 (Oregon)
- eu-west-1 (Ireland)
- ap-southeast-1 (Singapore)
- ap-northeast-1 (Tokyo)

### 4. Configure Goose Profile

Copy the `goose_profiles.yaml` to your Goose configuration directory:

```bash
mkdir -p ~/.config/goose
cp goose_profiles.yaml ~/.config/goose/profiles.yaml
```

The profile configuration tells Goose to use LiteLLM as an OpenAI-compatible provider.

### 5. Start the Services

**Start LiteLLM Proxy:**
```bash
litellm --config litellm_config.yaml
```

**In another terminal, start Goose:**
```bash
goose --profile bedrock-nova-lite
```

## Configuration Files Explained

### litellm_config.yaml
Configures LiteLLM to proxy requests to AWS Bedrock Nova Lite:
- `model`: Specifies the Bedrock model identifier
- `aws_region_name`: Your AWS region (defaults to us-east-1)
- Credentials are automatically read from AWS configuration

### goose_profiles.yaml
Configures Goose to use the LiteLLM proxy:
- `base_url`: Points to the LiteLLM proxy endpoint (http://localhost:4000/v1)
- `api_key_env`: Optional API key environment variable for LiteLLM proxy
- `models`: Maps the model name to the LiteLLM proxy model

## Troubleshooting

### LiteLLM Proxy Won't Start
- Check AWS credentials: `aws sts get-caller-identity`
- Verify boto3 installation: `python -c "import boto3"`
- Check AWS region availability for Nova Lite

### Goose Can't Connect to Proxy
- Ensure LiteLLM proxy is running on port 4000
- Check proxy logs for errors
- Verify the profile configuration in `~/.config/goose/profiles.yaml`

### AWS Permissions
Ensure your AWS user/role has the following Bedrock permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream"
            ],
            "Resource": "arn:aws:bedrock:*::foundation-model/amazon.nova-lite-v1:0"
        }
    ]
}
```

### Model Not Found
- Verify the model ID: `bedrock/amazon.nova-lite-v1:0`
- Check if Nova Lite is available in your region
- Update LiteLLM: `pip install --upgrade litellm`

## Advanced Configuration

### Using Environment Variables for Credentials
Instead of `~/.aws/credentials`, you can set environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION_NAME="us-east-1"
```

### Custom LiteLLM API Key
If you want to secure the LiteLLM proxy:

```bash
export LITELLM_API_KEY="your-secure-key"
```

Then update `goose_profiles.yaml` to use the API key.

### Multiple Models
You can add more Bedrock models to `litellm_config.yaml`:

```yaml
model_list:
  - model_name: bedrock-nova-lite
    litellm_params:
      model: bedrock/amazon.nova-lite-v1:0
      aws_region_name: us-east-1
  - model_name: bedrock-nova-pro
    litellm_params:
      model: bedrock/amazon.nova-pro-v1:0
      aws_region_name: us-east-1
```

### Changing AWS Region
Update the `aws_region_name` in `litellm_config.yaml` and restart the proxy.

## Architecture

```
┌─────────┐    ┌─────────────┐    ┌─────────────────┐
│  Goose  │───▶│  LiteLLM    │───▶│  AWS Bedrock     │
│   CLI   │    │   Proxy     │    │   Nova Lite      │
└─────────┘    └─────────────┘    └─────────────────┘
                     │
                     ▼
            ┌─────────────────┐
            │  AWS Credentials │
            │ (~/.aws/credentials) │
            └─────────────────┘
```

Goose sends OpenAI-compatible requests to the LiteLLM proxy, which translates them to AWS Bedrock API calls using your AWS credentials.

## Cost Optimization

- **Nova Lite** is Amazon's most cost-effective model:
  - Input: $0.06 per 1M tokens
  - Output: $0.24 per 1M tokens
- Monitor usage through AWS Bedrock console
- Consider reserved instances for high-volume usage

## Security Notes

- Credentials are stored locally in `~/.aws/credentials`
- LiteLLM proxy runs locally on `localhost:4000`
- No data is sent to external services except AWS
- Use AWS IAM best practices for credential management

## Updating

To update LiteLLM:
```bash
pip install --upgrade litellm boto3
```

To update Goose:
```bash
goose --help  # Check current version
# Download latest from: https://block.github.io/goose/docs/getting-started/installation
```

## Support

- **Goose Documentation**: https://block.github.io/goose/
- **LiteLLM Documentation**: https://docs.litellm.ai/
- **AWS Bedrock Nova**: https://docs.aws.amazon.com/nova/latest/userguide/

## Files in This Repository

- `litellm_config.yaml` - LiteLLM proxy configuration
- `goose_profiles.yaml` - Goose profile configuration
- `setup.sh` - Automated setup script
- `start.sh` - Start both proxy and Goose
- `README.md` - This documentation