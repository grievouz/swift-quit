# Swift Quit

A macOS menu bar app that quits applications after their last window closes.
Native settings, configurable delay, protected apps, and a recent activity list.
Hidden apps and apps with minimized or fullscreen windows stay running.

Requires macOS 13 or later and Accessibility access. Apps receive a normal quit
request so they can show save prompts.

## Installation

```sh
brew install --cask grievouz/tap/swift-quit
open "/Applications/Swift Quit.app"
```

Use the full tap name: Homebrew also distributes the original Swift Quit.
Enable **Swift Quit** in **System Settings → Privacy & Security → Accessibility**.
Releases are ad-hoc signed and not notarized by Apple.

## Development

```sh
make build
make test
make run
```

The project uses SwiftPM with no external dependencies. Source and bundled
artwork live in `Sources/SwiftQuit`; tests live in `Tests`; build and release
scripts live in `scripts`.

Run `make install` to install a local build. Set `SWIFT_QUIT_SIGN_ID` to use
your own signing identity; local builds otherwise use ad-hoc signing.

To inspect the UI without monitoring or quitting apps:

```sh
open -n "build/Swift Quit.app" --args --preview-ui
```

## Releasing

Update `VERSION`, commit, and publish a GitHub release tagged `vX.Y.Z`.
The release workflow tests the project, builds a universal macOS app, uploads
DMG/ZIP archives, matching source and checksums, and updates
`Casks/swift-quit.rb` in `grievouz/homebrew-tap`.

Set `HOMEBREW_TAP_TOKEN` as a repository secret with Contents read/write access
to `grievouz/homebrew-tap`. `make package` builds the same assets locally.
Releases are ad-hoc signed and not notarized.

## License

[GPL-3.0](LICENSE). Based on [Hush](https://github.com/jspw/Hush), whose
[MIT notice](LICENSES/Hush-MIT.txt) is preserved. Artwork comes from
[Swift Quit](https://github.com/onebadidea/swiftquit).
See [NOTICE.md](NOTICE.md) for attribution. This is an independent project.
