# Epub Reader

An open source book reader developed in Flutter for Android ([And eventually other platforms as well](#what-about-other-platforms)).

## Preview

coming soon...

## Running from source

1. clone `https://github.com/FlafyDev/epub_reader` somewhere.
2. clone `https://github.com/FlafyDev/epub-renderer` somewhere.
3. in `epub-renderer` do `yarn build --outDir ..../epub_reader/assets`.
4. in `epub_reader` do `flutter pub get && flutter run`.

## What about other platforms?

- IOS: I don't have a device to test it on.
- Web: Would require a lot of changes and there isn't a stable webview package for web.
- Windows: Blocked on [#37597](https://github.com/flutter/flutter/issues/37597)
- MacOS: Blocked on [#41725](https://github.com/flutter/flutter/issues/41725)
- Linux: Blocked on [#41726](https://github.com/flutter/flutter/issues/41726)

## License

[GNU GENERAL PUBLIC LICENSE Version 3](LICENSE)