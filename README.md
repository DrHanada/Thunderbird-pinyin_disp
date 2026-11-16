# Thunderbird Pinyin Display

メール本文で選択した簡体字中国語のピンインをポップアップ表示するThunderbirdアドオンです。

- Thunderbird 160.0 (64-bit) で利用者による動作確認済み
- ピンイン変換: [pinyin-pro 3.29.5](https://github.com/zh-lx/pinyin-pro) (MIT License)
- Node.js / npm は不要です
- 変換はローカルで行います。辞書スクリプトを一度ダウンロードした後は、実行時のネット接続は必要ありません

## セットアップ

1. リポジトリをダウンロードまたはクローンします。
2. `vendor` フォルダーを作成します。
3. pinyin-pro 3.29.5 のブラウザー向けビルドをダウンロードし、`vendor/pinyin-pro.js` として保存します。

Windows PowerShellでは、リポジトリのルートで次を実行できます。

```powershell
New-Item -ItemType Directory -Force vendor | Out-Null
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/pinyin-pro@3.29.5/dist/index.js" -OutFile "vendor/pinyin-pro.js"
```

ダウンロード元は pinyin-pro の公開npm配布物を提供する jsDelivr CDN です。拡張機能はこのファイルをローカルで読み込みます。CDNへのアクセスができない場合は、公式リポジトリまたはnpm配布物から同バージョンのブラウザー向け `dist/index.js` を取得してください。

## Thunderbirdで一時的に試す

1. Thunderbirdで `about:debugging` を開き、「この Thunderbird」を選択します。
2. 「一時的なアドオンを読み込む」を選び、リポジトリ内の `manifest.json` を指定します。
3. メールを開き、本文中の簡体字中国語をドラッグして選択し、マウスボタンを離します。
4. 選択した文字とピンインがポップアップに表示されます。

この方法で読み込んだアドオンは一時的なものです。Thunderbird再起動後は必要に応じて再読み込みしてください。

## ファイル

- `manifest.json`: Thunderbirdアドオンの定義。`messageDisplayScripts` の利用に `messagesModify` 権限を指定しています。
- `background.js`: メール表示用スクリプトを登録します。
- `content.js`: 選択範囲を検出してピンインのポップアップを表示します。
- `vendor/pinyin-pro.js`: セットアップ時に取得するpinyin-proブラウザー向けビルド (Git管理対象外)。

## ライセンス

このアドオンの独自コードはMIT Licenseで提供します。`pinyin-pro` は別プロジェクトで、MIT Licenseのもと提供されています。ライブラリ本体とライセンス表記は[公式リポジトリ](https://github.com/zh-lx/pinyin-pro)を参照してください。
