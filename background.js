const api = globalThis.messenger ?? globalThis.browser;

if (!api?.messageDisplayScripts) {
  console.error(
    "Pinyin Display: messageDisplayScripts API が利用できません。",
    { messenger: typeof globalThis.messenger, browser: typeof globalThis.browser }
  );
} else {
  api.messageDisplayScripts.register({
    js: [
      { file: "vendor/pinyin-pro.js" },
      { file: "content.js" }
    ]
  }).catch((error) => {
    console.error("Pinyin Display: スクリプトを登録できませんでした。", error);
  });
}
