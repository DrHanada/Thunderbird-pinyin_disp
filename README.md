# Thunderbird Pinyin Display

Thunderbird add-on that displays pinyin for selected Simplified Chinese text in an email message.

## Release and compatibility

- Current add-on version: `0.1.1`.
- User-tested with Thunderbird 160.0 (64-bit).
- English is the default locale; Japanese localization is included.
- The add-on icon is provided in `icons/` and declared in `manifest.json`.
- Pinyin conversion uses the npm dependency `pinyin-pro` version 3.29.5.
- Selected text is processed locally and is not sent to an external service.

## Build the XPI

Requirements: Node.js and npm for the build only. They are not required at runtime. From the repository root, run:

```sh
npm install
npm run build