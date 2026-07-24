(function () {
  const COPY_ICON =
    '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2">' +
    '<rect x="9" y="9" width="12" height="12" rx="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" stroke-linecap="round" stroke-linejoin="round"/>' +
    "</svg>";
  const CHECK_ICON =
    '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2">' +
    '<path d="M20 6L9 17l-5-5" stroke-linecap="round" stroke-linejoin="round"/>' +
    "</svg>";

  const messagesEl = document.getElementById("messages");
  const emptyStateEl = document.getElementById("emptyState");
  const chatScrollEl = document.getElementById("chatScroll");
  const inputEl = document.getElementById("input");
  const sendBtn = document.getElementById("sendBtn");
  const newChatBtn = document.getElementById("newChatBtn");
  const statusDot = document.getElementById("statusDot");
  const statusText = document.getElementById("statusText");

  /** @type {{role: "user" | "assistant", content: string}[]} */
  let conversation = [];

  function scrollToBottom() {
    chatScrollEl.scrollTop = chatScrollEl.scrollHeight;
  }

  function autoResize() {
    inputEl.style.height = "auto";
    inputEl.style.height = Math.min(inputEl.scrollHeight, 200) + "px";
  }

  function renderMessage(role, content, { loading = false } = {}) {
    emptyStateEl.classList.add("hidden");

    const wrapper = document.createElement("div");
    wrapper.className = `msg ${role}`;

    const avatar = document.createElement("div");
    avatar.className = "avatar";
    avatar.textContent = role === "user" ? "U" : "AI";

    const col = document.createElement("div");
    col.className = "msg-col";

    const bubble = document.createElement("div");
    bubble.className = "bubble-content" + (loading ? " loading" : "");

    if (loading) {
      bubble.innerHTML =
        '<span class="typing-dot"></span><span class="typing-dot"></span><span class="typing-dot"></span>';
    } else {
      bubble.textContent = content;
    }

    col.appendChild(bubble);

    // Assistant messages get a hover action bar with a copy button,
    // matching ChatGPT's per-message actions.
    if (!loading) {
      const actions = document.createElement("div");
      actions.className = "msg-actions";

      const copyBtn = document.createElement("button");
      copyBtn.className = "copy-btn";
      copyBtn.type = "button";
      copyBtn.title = "Copy";
      copyBtn.setAttribute("aria-label", "Copy message");
      copyBtn.innerHTML = COPY_ICON;

      copyBtn.addEventListener("click", async () => {
        try {
          await navigator.clipboard.writeText(content);
        } catch {
          // clipboard API can fail (e.g. insecure context) — fall back silently
          const ta = document.createElement("textarea");
          ta.value = content;
          ta.style.position = "fixed";
          ta.style.opacity = "0";
          document.body.appendChild(ta);
          ta.select();
          document.execCommand("copy");
          document.body.removeChild(ta);
        }
        copyBtn.innerHTML = CHECK_ICON;
        copyBtn.classList.add("copied");
        setTimeout(() => {
          copyBtn.innerHTML = COPY_ICON;
          copyBtn.classList.remove("copied");
        }, 1500);
      });

      actions.appendChild(copyBtn);
      col.appendChild(actions);
    }

    wrapper.appendChild(avatar);
    wrapper.appendChild(col);
    messagesEl.appendChild(wrapper);
    scrollToBottom();
    return wrapper;
  }

  async function checkHealth() {
    try {
      const res = await fetch("/api/health");
      const data = await res.json();
      if (data.endpoint_configured) {
        statusDot.classList.add("online");
        statusText.textContent = "Endpoint connected";
      } else {
        statusDot.classList.add("offline");
        statusText.textContent = "Endpoint not configured (.env)";
      }
    } catch {
      statusDot.classList.add("offline");
      statusText.textContent = "Backend unreachable";
    }
  }

  async function sendMessage() {
    const text = inputEl.value.trim();
    if (!text) return;

    conversation.push({ role: "user", content: text });
    renderMessage("user", text);

    inputEl.value = "";
    autoResize();
    sendBtn.disabled = true;

    const loadingBubble = renderMessage("assistant", "", { loading: true });

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: conversation }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.detail || `Request failed (${res.status})`);
      }

      conversation.push({ role: "assistant", content: data.answer });
      loadingBubble.remove();
      renderMessage("assistant", data.answer);
    } catch (err) {
      loadingBubble.remove();
      const errorEl = renderMessage("assistant", `⚠ ${err.message}`);
      errorEl.classList.add("error");
    } finally {
      sendBtn.disabled = false;
      inputEl.focus();
    }
  }

  inputEl.addEventListener("input", autoResize);

  inputEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });

  sendBtn.addEventListener("click", sendMessage);

  newChatBtn.addEventListener("click", () => {
    conversation = [];
    messagesEl.innerHTML = "";
    emptyStateEl.classList.remove("hidden");
    inputEl.value = "";
    autoResize();
    inputEl.focus();
  });

  checkHealth();
})();


