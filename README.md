# Thunderbird Pinyin Display

Thunderbird add-on that displays pinyin for selected Simplified Chinese text in an email message.

## First release

- Add-on version: `0.1.0` (see `manifest.json`).
- Verified by the user in Thunderbird 160.0 (64-bit).
- Pinyin conversion uses the browser build of [pinyin-pro 3.29.5](https://github.com/zh-lx/pinyin-pro), distributed under the MIT License.
- Conversion runs locally. The add-on does not send selected text or message content to an external service.
- Node.js and npm are not required to build the XPI.

## Build the XPI on Windows

Requirements: Windows PowerShell and network access for the first build. The build script downloads the pinned pinyin-pro browser bundle and its license notices into `vendor/` if they are not already present. The add-on itself has no runtime network dependency.

1. Download or clone this repository.
2. Open PowerShell in the repository directory.
3. Run the complete build script:

   ```powershell
   .\build-xpi.ps1
   ```

The script reads the version from `manifest.json`, creates `thunderbird-pinyin-display-0.1.0.xpi`, and validates the archive entries. ZIP paths use `/` separators, `manifest.json` is at the archive root, the bundled library and third-party notices are included, and referenced icons are included if configured in the manifest.

Do not run only selected lines of the script. If Windows PowerShell reports an execution-policy error, review the local policy and run the script according to your organization's security requirements.

## Temporary installation for testing

1. In Thunderbird, open `about:debugging` and select **This Thunderbird**.
2. Choose **Load Temporary Add-on** and select `manifest.json` from this repository.
3. Open an email, select Simplified Chinese text in its body, and release the mouse button.
4. The selected text and its pinyin should appear in a popup.

Temporary add-ons may need to be loaded again after Thunderbird restarts.

## AMO submission source

Upload a ZIP of the source files used to produce the submitted XPI, not the XPI itself as the source archive. Include `manifest.json`, `background.js`, `content.js`, `build-xpi.ps1`, this README, `LICENSE`, and the exact `vendor/pinyin-pro.js` and third-party license files included in the submitted XPI. Include any icons referenced by the manifest. Exclude `.git`, temporary files, and generated XPI files.

The build script downloads the pinned dependency and notices when absent. For a source submission that must contain every build input, run the script once first, then include the populated `vendor/` directory in the source ZIP. The XPI submitted to AMO and the source bundle must use the same dependency version and source files.

## Manifest notes

- `messagesModify` is required by Thunderbird's `messageDisplayScripts` API. AMO's Firefox-oriented validator may report it as an unsupported-permission warning; do not remove it for the Thunderbird build.
- `data_collection_permissions.required` is `none` because the add-on does not collect or transmit user data. Update this declaration if that behavior changes.
- The minimum Gecko version is 142.0 to satisfy AMO's data-collection declaration validator. The add-on was tested by the user on Thunderbird 160.0.

## Licenses

The add-on's original code is provided under the MIT License in `LICENSE`. The bundled pinyin-pro code and its data dependency have separate upstream MIT license notices, downloaded by the build script into `vendor/PINYIN-PRO-LICENSE.txt` and `vendor/PINYIN-PRO-DATA-LICENSE.txt`. See the [pinyin-pro repository](https://github.com/zh-lx/pinyin-pro).
