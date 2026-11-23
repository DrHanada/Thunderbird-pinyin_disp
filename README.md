# Thunderbird Pinyin Display

Thunderbird add-on that displays pinyin for selected Simplified Chinese text in an email message.

## Release and compatibility

- Current add-on version: `0.1.1`.
- User-tested with Thunderbird 160.0 (64-bit).
- English is the default locale; Japanese localization is included.
- Pinyin conversion uses the npm dependency `pinyin-pro` version 3.29.5.
- Selected text is processed locally and is not sent to an external service.

## Build the XPI

Requirements: Node.js and npm for the build only. They are not required at runtime. From the repository root, run:

```sh
npm install
npm run build
```

The build script uses the exact direct dependency versions in `package.json`, bundles the pinyin-pro dependency with esbuild, packages the localized extension files, and writes the XPI to `dist/thunderbird-pinyin-display-0.1.1.xpi`. The ZIP entries use forward-slash paths and `manifest.json` is at the archive root.

The XPI contains a generated browser bundle under `vendor/`. That generated file is not source code and must not be included in the AMO source-code archive.

## AMO source-code archive

Create a ZIP containing the readable build inputs:

- `manifest.json`, `background.js`, `content.js`
- `_locales/en/messages.json` and `_locales/ja/messages.json`
- `package.json` and `build.mjs`
- `README.md`, `LICENSE`, and `THIRD_PARTY_NOTICES.md`

Do **not** include `dist/`, any `.xpi`, `node_modules/`, or generated/bundled `vendor/pinyin-pro.js`. The dependency is declared in `package.json` and installed by npm as part of the build. The source archive must describe how to reproduce the submitted XPI using the commands above.

## Permissions and data collection

`messagesModify` is needed for Thunderbird's `messageDisplayScripts` API. AMO's Firefox-oriented validator may report it as an unsupported-permission warning; retain it for Thunderbird. The add-on does not collect or transmit user data, so `data_collection_permissions.required` is set to `none`.

## Testing

1. Run the build and locate the XPI in `dist/`.
2. In Thunderbird, open `about:debugging`, select **This Thunderbird**, then **Load Temporary Add-on** and choose the generated XPI or the manifest in the staged extension.
3. Open an email, select Simplified Chinese text, and release the mouse button. The selection and its pinyin should appear in a popup.

## Licenses

The add-on's original code is MIT-licensed; see `LICENSE`. The bundled pinyin-pro library and its pinyin data dependency have separate MIT notices in `THIRD_PARTY_NOTICES.md`.
