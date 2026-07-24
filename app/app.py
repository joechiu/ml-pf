import os
import logging
from pathlib import Path

import requests
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("pf-chat-app")

AZURE_ENDPOINT_URL = os.getenv("OK_AZUREML_ENDPOINT_API")
AZURE_API_KEY= os.getenv("OK_AZUREML_ENDPOINT_KEY")
AZURE_DEPLOYMENT_NAME = "yellow"
REQUEST_TIMEOUT_SECS = float(180)

BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"

app = FastAPI(title="Prompt Flow Chat")

# Allow the local static page to call the API without CORS headaches
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]


class ChatResponse(BaseModel):
    answer: str


@app.get("/")
def serve_index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/api/health")
def health():
    return {
        "status": "ok",
        "endpoint_configured": bool(AZURE_ENDPOINT_URL and AZURE_API_KEY),
    }


@app.post("/api/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    if not AZURE_ENDPOINT_URL or not AZURE_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Server is missing AZURE_ENDPOINT_URL / AZURE_API_KEY. "
                   "Set them in your .env file and restart the app.",
        )

    if not req.messages:
        raise HTTPException(status_code=400, detail="No messages provided.")

    # The deployed flow only accepts a single `message` string input (see
    # flow.dag.yaml), it doesn't take a conversation array. We send just the
    # latest user turn — if you want the flow itself to be context-aware,
    # that needs to change in flow.dag.yaml/prompt.jinja2, not here.
    last_user_message = next(
        (m.content for m in reversed(req.messages) if m.role == "user"), None
    )
    if last_user_message is None:
        raise HTTPException(status_code=400, detail="No user message found.")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {AZURE_API_KEY}",
    }
    if AZURE_DEPLOYMENT_NAME:
        headers["azureml-model-deployment"] = AZURE_DEPLOYMENT_NAME

    payload = {"message": last_user_message}

    try:
        resp = requests.post(
            AZURE_ENDPOINT_URL,
            headers=headers,
            json=payload,
            timeout=REQUEST_TIMEOUT_SECS,
        )
        resp.raise_for_status()
    except requests.exceptions.Timeout:
        logger.warning("Endpoint timed out after %ss", REQUEST_TIMEOUT_SECS)
        raise HTTPException(status_code=504, detail="The model endpoint timed out.")
    except requests.exceptions.HTTPError as e:
        logger.warning("Endpoint returned an error: %s | body=%s", e, resp.text[:500])
        raise HTTPException(
            status_code=502,
            detail=f"Endpoint returned {resp.status_code}: {resp.text[:300]}",
        )
    except requests.exceptions.RequestException as e:
        logger.warning("Request to endpoint failed: %s", e)
        raise HTTPException(status_code=502, detail=f"Could not reach the endpoint: {e}")

    try:
        data = resp.json()
    except ValueError:
        raise HTTPException(status_code=502, detail="Endpoint did not return valid JSON.")

    answer = data.get("answer")
    if answer is None:
        # be forgiving about slightly different response shapes
        answer = data.get("output") or data.get("result") or str(data)

    return ChatResponse(answer=answer)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="0.0.0.0", port=8888, reload=True)


