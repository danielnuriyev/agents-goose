# Goose Task Server

This project runs Goose behind a local HTTP task server.

The goal is to call this server from Slack and other applications.

## Files

- `setup.sh` - install and configure everything
- `litellm_config.yaml` - LiteLLM model mapping.
- `goose_config.yaml` - Local Goose configuration for the task server
- `goose_server.py` - local HTTP task server
- `goose_client.py` - Python client (`submit_task`, `get_task_status`)
- `goose_task.py` - CLI script to submit tasks and optionally wait for completion

## 1) Setup

```bash
cd agents-goose
chmod +x setup.sh
./setup.sh
```

If needed, configure AWS credentials:

```bash
aws configure
```

## 2) Run services

Terminal 1 (LiteLLM proxy):

```bash
cd agents-goose
source .venv/bin/activate
litellm --config litellm_config.yaml --port 4321
```

Terminal 2 (task server):

```bash
cd agents-goose
source .venv/bin/activate
python goose_server.py
```

## 3) Run test client

Terminal 3:

```bash
cd agents-goose
source .venv/bin/activate
python goose_task.py --task "Write a hello world program in Python" --wait
```

You can optionally specify a different model (defaults to `bedrock-claude-opus-4-6`):

```bash
python goose_task.py --task "Write a hello world program" --model bedrock-claude-opus-4-6 --wait
```

It submits the task, waits for completion, and shows the final status and output.

## API

- `GET /health`: Health check endpoint
- `GET /models`: Get available models from LiteLLM
- `POST /tasks` with body:

```json
{
  "task": "Write exactly one line: Hello, world!",
  "model": "bedrock-claude-opus-4-6"
}
```

- `GET /tasks`: List all tasks
- `GET /tasks/<task_id>`: Get specific task status (`queued`, `running`, `completed`, `failed`) and output

Example usage with Python client:

```python
from goose_client import GooseTaskClient

client = GooseTaskClient()

# Get available models
models = client.get_models()
print("Available models:", [m["id"] for m in models])

# Submit a task
response = client.submit_task("Create a hello.py file", model="bedrock-claude-opus-4-6")
task_id = response["task_id"]

# Wait for completion
result = client.wait_for_done(task_id)
print("Task result:", result)
```

## Notes

- Goose config is managed in `goose_config.yaml` (created manually).
- The task server uses `goose_config.yaml` as its local configuration, isolated from your global Goose settings.
- Required keys are uppercase: `GOOSE_PROVIDER`, `GOOSE_MODEL`, `LITELLM_HOST`, `LITELLM_BASE_PATH`.
- The task server runs Goose with bounded turns/retries to prevent runaway executions.
