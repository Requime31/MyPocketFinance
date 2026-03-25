fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios ci

```sh
[bundle exec] fastlane ios ci
```

CI: Debug-сборка для iOS Simulator (как в GitHub Actions ci)

### ios artifact_simulator_release

```sh
[bundle exec] fastlane ios artifact_simulator_release
```

Release-сборка симулятора и zip в корне репозитория (для GitHub Artifact)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

TestFlight: нужны платная подписка Apple Developer, API-ключ App Store Connect и подпись (match или сертификаты на раннере).
Секреты: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY.
Раскомментируйте код в конце lane после настройки match.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
