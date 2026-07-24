(function () {
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

    const bubble = document.createElement("div");
    bubble.className = "bubble-content" + (loading ? " loading" : "");

    if (loading) {
      bubble.innerHTML =
        '<span class="typing-dot"></span><span class="typing-dot"></span><span class="typing-dot"></span>';
    } else {
      bubble.textContent = content;
    }

    wrapper.appendChild(avatar);
    wrapper.appendChild(bubble);
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
