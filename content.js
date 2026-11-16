(() => {
  // メール本文に複数回初期化されてもポップアップを重複作成しない
  if (window.__thunderbirdPinyinDisplayInitialized) {
    return;
  }
  window.__thunderbirdPinyinDisplayInitialized = true;

  const host = document.createElement("div");
  host.setAttribute("aria-live", "polite");
  host.style.cssText = [
    "all: initial",
    "position: fixed",
    "z-index: 2147483647",
    "display: none",
    "pointer-events: none"
  ].join(";");

  const shadow = host.attachShadow({ mode: "closed" });
  const popup = document.createElement("div");
  popup.style.cssText = [
    "box-sizing: border-box",
    "max-width: min(420px, calc(100vw - 24px))",
    "padding: 10px 12px",
    "border: 1px solid #c9cdd3",
    "border-radius: 8px",
    "background: #fff",
    "color: #202124",
    "box-shadow: 0 3px 14px rgba(0, 0, 0, .2)",
    "font: 14px/1.5 sans-serif",
    "white-space: normal",
    "overflow-wrap: anywhere"
  ].join(";");

  shadow.appendChild(popup);

  function getPinyin(text) {
    const library = globalThis.pinyinPro;
    if (!library || typeof library.pinyin !== "function") {
      throw new Error("pinyin-pro が読み込まれていません");
    }
    return library.pinyin(text, { toneType: "symbol" });
  }

  function showSelection() {
    const selection = window.getSelection();
    const text = selection ? selection.toString().trim() : "";

    // 長すぎる選択や漢字を含まない選択には反応しない
    if (!text || text.length > 120 || !/\p{Script=Han}/u.test(text)) {
      host.style.display = "none";
      return;
    }

    let result;
    try {
      result = getPinyin(text);
    } catch (error) {
      console.error("Pinyin Display:", error);
      host.style.display = "none";
      return;
    }

    popup.replaceChildren();

    const selected = document.createElement("div");
    selected.textContent = text;
    selected.style.cssText = "font-weight: 600; margin-bottom: 3px;";

    const reading = document.createElement("div");
    reading.textContent = result;
    reading.style.cssText = "color: #3c4655;";

    popup.append(selected, reading);

    if (!host.isConnected) {
      document.documentElement.appendChild(host);
    }

    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect();
    const margin = 8;

    host.style.display = "block";
    host.style.left = `${Math.max(margin, Math.min(rect.left, window.innerWidth - 440))}px`;

    // 表示後に高さを測り、画面下端からはみ出す場合は選択範囲の上に出す
    const popupHeight = host.getBoundingClientRect().height;
    const top = rect.bottom + 8 + popupHeight < window.innerHeight
      ? rect.bottom + 8
      : Math.max(margin, rect.top - popupHeight - 8);

    host.style.top = `${top}px`;
  }

  document.addEventListener("mouseup", showSelection, true);
  document.addEventListener("keyup", showSelection, true);
  document.addEventListener("mousedown", (event) => {
    if (!host.contains(event.target)) {
      host.style.display = "none";
    }
  }, true);
})();
