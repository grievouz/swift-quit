#!/usr/bin/env python3
"""Write the Swift Quit cask from the actual universal DMG's SHA-256."""
import argparse
import hashlib
from pathlib import Path
import re


def cask_text(version: str, digest: str) -> str:
    return f'''cask "swift-quit" do
  version "{version}"
  sha256 "{digest}"

  url "https://github.com/grievouz/swift-quit/releases/download/v#{{version}}/swift-quit-#{{version}}-universal.dmg"
  name "Swift Quit"
  desc "Quit apps after their last window closes"
  homepage "https://github.com/grievouz/swift-quit"

  depends_on macos: ">= :ventura"

  app "Swift Quit.app"

  uninstall quit: "io.github.grievouz.SwiftQuit"

  zap trash: "~/Library/Preferences/io.github.grievouz.SwiftQuit.plist"

  caveats do
    <<~EOS
      Enable Swift Quit in System Settings > Privacy & Security > Accessibility.
      Releases are ad-hoc signed and are not notarized by Apple.
    EOS
  end
end
'''


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("dmg", type=Path)
    parser.add_argument("tap", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"v\d+\.\d+\.\d+", args.tag):
        parser.error("expected a stable release tag like v1.2.3")
    version = args.tag[1:]
    if args.dmg.name != f"swift-quit-{version}-universal.dmg":
        parser.error("DMG filename must match the release version and universal architecture")
    target = args.tap / "Casks" / "swift-quit.rb"
    if target.exists():
        old = re.search(r'^  version "(\d+\.\d+\.\d+)"$', target.read_text(), re.MULTILINE)
        if old and tuple(map(int, old[1].split("."))) > tuple(map(int, version.split("."))):
            parser.error("refusing to downgrade the existing cask")
    checksum = hashlib.sha256()
    with args.dmg.open("rb") as archive:
        for chunk in iter(lambda: archive.read(1024 * 1024), b""):
            checksum.update(chunk)
    digest = checksum.hexdigest()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(cask_text(version, digest))
    print(f"Updated {target}: {version}, SHA-256 {digest}")


if __name__ == "__main__":
    main()
