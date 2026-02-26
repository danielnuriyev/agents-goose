# Skein

Goals:
- To wrap [Goose](https://github.com/block/goose) in a RESTful server in order to call it from Slack and other products.
- To have a broader selection of models
- To make it easy to add tools
- To have more ways of using Goose

## Files

- `setup.sh` - install and configure everything
- `start_server.sh` - start both LiteLLM proxy and Goose task server
- `stop_server.sh` - stop both LiteLLM proxy and Goose task server
- `start_prompt.sh` - interactive prompt for submitting tasks
- `start_slack.sh` - start Slack middleware server for slash command integration
- `slack_server.py` - Bottle middleware server bridging Slack to Goose tasks
- `litellm_config.yaml` - LiteLLM model mapping.
- `goose_config.yaml` - Local Goose configuration for the task server
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

I haven't played with the other major clouds yet.

## 2) Run services

### Option 1: Automated startup script (recommended)

```bash
cd agents-goose
./start_server.sh
```

This script will automatically:
- Kill any existing processes on ports 4321 and 8765 (restart mode, default)
- Activate the virtual environment
- Start both LiteLLM proxy and Goose task server in the background
- Display PIDs and stop commands

AWS credential behavior:
- `start_server.sh` uses profile-based AWS auth (`AWS_PROFILE`, default `default`)
- It clears static `AWS_*KEY*` env vars before launching LiteLLM
- Use refreshable profile credentials (for example SSO/credential_process) for best no-restart behavior

#### Options:
- `--restart` (default): Restart services if already running
- `--no-restart`: Only start services if they're not already running
- `--help`: Show usage information

#### Examples:
```bash
./start_server.sh              # Start/restart services (default)
./start_server.sh --restart    # Same as default
./start_server.sh --no-restart # Only start if not running
```

### Stopping services

```bash
cd agents-goose
./stop_server.sh
```

This script will:
- Stop both LiteLLM proxy and Goose task server
- Report success/failure status
- Handle cases where services are already stopped

### Interactive task prompt

```bash
cd agents-goose
./start_prompt.sh
```

This starts an interactive session where you can submit tasks without leaving the terminal:

```
goose> task "Write a hello world program in Python"
goose> task mytask.md
goose> help
goose> quit
```

Available commands:
- `task "your task here"` - Submit a task as text
- `task filename.md` - Submit a task from a markdown file
- `help` - Show available commands
- `quit`/`exit`/`q` - Exit the interactive session

### Slack integration

```bash
cd agents-goose
./start_slack.sh
```

This starts a middleware server that bridges Slack slash commands to Goose tasks.
The server uses Bottle (a lightweight WSGI micro-framework) for minimal dependencies and fast performance.

#### Setup steps:

1. **Start the Slack server:**
   ```bash
   ./start_slack.sh              # Start on port 3000 (default)
   ./start_slack.sh --port 8080  # Start on custom port
   ```

2. **Expose the server publicly:**
   ```bash
   # Install ngrok from https://ngrok.com/download
   ngrok http 3000
   ```
   Copy the ngrok URL (e.g., `https://abc123.ngrok.io`)

3. **Create a Slack App:**
   - Go to [https://api.slack.com/apps](https://api.slack.com/apps)
   - Click "Create New App" → "From scratch"
   - Name your app (e.g., "Goose Bot") and select your workspace

4. **Add a Slash Command:**
   - In your Slack app, go to "Slash Commands" → "Create New Command"
   - Command: `/goose` (or your preferred command name)
   - Request URL: `https://your-ngrok-url.ngrok.io/slack/command`
   - Description: "Submit tasks to Goose AI agent"
   - Usage Hint: `<your task description>`

5. **Install the app to your workspace:**
   - Go to "OAuth & Permissions" → "Scopes"
   - Add `commands` scope
   - Go to "Install App" and install it to your workspace

#### Usage:

In any Slack channel where the app is installed:
```
/goose Create a Python function to calculate fibonacci numbers
/goose Fix the bug in my code: the function returns None instead of the result
/goose Write a README for my project
```

The bot will:
- Immediately acknowledge your command
- Process the task asynchronously
- Send the results back to the channel when complete

#### Environment variables:

- `SLACK_SIGNING_SECRET`: For request verification (recommended for production)
- `GOOSE_SERVER_URL`: URL of goose_server.py (default: `http://localhost:8765`)

#### Troubleshooting:

- Ensure `./start_server.sh` is running first (starts Goose and LiteLLM)
- Check logs: `tail -f .logs/slack_server.log`
- Use `lsof -ti:3000 | xargs kill -9` to stop the Slack server

### Option 2: Manual startup

## Run test client

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
