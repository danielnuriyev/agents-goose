# Goose + LiteLLM

This folder sets up Goose to use models through a local LiteLLM proxy.
This is a work in progress. My goal is to automate things that I do routinely.

## What `setup.sh` does

Running `./setup.sh` will do most of the work:

- installs `uv` (if missing)
- installs Goose CLI (if missing)
- creates `.venv` with system Python (`/usr/bin/python3`)
- installs LiteLLM proxy dependencies with `uv` (`litellm[proxy]`, `boto3`, `python-multipart`)
- writes `~/.config/goose/config.yaml` for LiteLLM
- keeps a backup of your previous Goose config if it exists

`setup.sh` writes these required Goose keys:

- `GOOSE_PROVIDER: litellm`
- `GOOSE_MODEL: bedrock-nova-lite`
- `LITELLM_HOST: http://localhost:4000`
- `LITELLM_BASE_PATH: v1/chat/completions`

## 1) Download

```bash
git clone <your-repo-url>
cd agents-goose
```

## 2) Install + Configure

```bash
chmod +x setup.sh
./setup.sh
```

If you do not have AWS credentials yet:

```bash
aws configure
```

## 3) Run

Start LiteLLM proxy in terminal 1:

```bash
cd agents-goose
source .venv/bin/activate
litellm --config litellm_config.yaml
```

Run Goose in terminal 2:

```bash
goose run --text "Write a hello world program in Python"
```

## 4) Verify it is using Bedrock Nova Lite

- LiteLLM config is in `litellm_config.yaml`
- model route is `bedrock/amazon.nova-lite-v1:0`
- Goose config is written to `~/.config/goose/config.yaml`

## Common error

If you see a Bedrock authorization error, add IAM permissions for:

- `bedrock:InvokeModel`
- `bedrock:InvokeModelWithResponseStream`

If LiteLLM fails with `uvloop`/Python 3.14 import errors, rerun `./setup.sh` to recreate `.venv` with a supported Python version.

If Goose says `No provider configured`, rerun `./setup.sh` and verify `~/.config/goose/config.yaml` contains `GOOSE_PROVIDER` and `GOOSE_MODEL` (uppercase keys).