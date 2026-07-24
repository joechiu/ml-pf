# Prompt Flow Chat

A local ChatGPT-style web app (FastAPI + vanilla JS) that sends messages to your
deployed Azure ML Prompt Flow endpoint (`ok-tool1-api` / `yellow` deployment)
and displays the responses.

## How it maps to your flow

- `flow.dag.yaml` expects a single input `message: string` and returns
  `answer: string` — the backend (`main.py`) sends `{"message": "<latest user turn>"}`
  to your endpoint and reads `answer` back from the JSON response.
- The flow itself has no memory of previous turns (it's a single `message` input,
  no history array) — this app keeps the full conversation in the browser for
  display, but only sends the latest user message to the endpoint, matching what
  the flow actually accepts. If you want the model to see prior turns, that
  needs to change in `prompt.jinja2`/`flow.dag.yaml` on the flow side, not here.
- `yellow-ok.yml`'s `request_timeout_ms: 180000` is mirrored by
  `REQUEST_TIMEOUT_SECS=180` in `.env`.

## Setup

```bash
cd pf-chat-app
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env`:

```
AZURE_ENDPOINT_URL=https://ok-tool1-api.<region>.inference.ml.azure.com/score
AZURE_API_KEY=<key from the endpoint's "Consume" tab in Azure ML Studio>
AZURE_DEPLOYMENT_NAME=yellow
REQUEST_TIMEOUT_SECS=180
```

You can find `AZURE_ENDPOINT_URL` and `AZURE_API_KEY` in Azure ML Studio →
Endpoints → `ok-tool1-api` → Consume tab (REST endpoint + primary key).

## Run

```bash
uvicorn app:app --reload --port 8888
```

Then open **http://localhost:8888** — you'll see a ChatGPT-style page. The
sidebar shows a live green/red dot for whether the endpoint is configured
and reachable; "New chat" clears the conversation locally (no server state
is kept between requests).

## Notes

- CORS is wide open (`allow_origins=["*"]`) for local development
  convenience — tighten this before deploying anywhere shared.
- Errors from the endpoint (timeouts, non-200 responses, bad JSON) are
  caught and shown inline in the chat as an assistant message prefixed
  with ⚠, instead of crashing the page.
- No conversation is persisted to disk — refreshing the page clears history.
```
# id=$(az ml online-endpoint show \
  --name ok-tool1-api \
  --resource-group $rg \
  --workspace-name $ws \
  --query identity)
# az role assignment create \
  --role "Azure Machine Learning Workspace Connection Secrets Reader" \
  --assignee $id \
  --scope /subscriptions/xxx/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/$ws

az ml online-deployment update \
     --name yellow \
     --endpoint-name $ep \
     --resource-group $rg \
     --workspace-name $ws \
     --set instance_count=1
```
