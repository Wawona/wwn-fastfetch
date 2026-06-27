#!/usr/bin/env python3
"""Verify fastfetch Apple-mobile compliance patches still apply to upstream anchors."""
from pathlib import Path
import subprocess
import sys
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
PATCH_DIR = ROOT / "dependencies" / "clients" / "fastfetch" / "patches"
URL = "https://github.com/fastfetch-cli/fastfetch/archive/refs/tags/2.64.2.tar.gz"

BANNED_IN_MOBILE_PATCH = ("fork(", "execve(", "posix_spawn", "posix_spawnp", "system(")


def apply_patches(src: Path) -> None:
    for script in ("apply-wawona-wayland-macos.py", "patch-fastfetch-apple-mobile.py"):
        subprocess.check_call(["python3", str(PATCH_DIR / script)], cwd=src)
    for name, dest in (
        ("processing_apple_mobile.c", "src/common/impl/processing_linux.c"),
        ("netif_apple_mobile.c", "src/common/impl/netif_apple.c"),
    ):
        (src / dest).write_text((PATCH_DIR / name).read_text())


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tgz = Path(tmp) / "src.tar.gz"
        urllib.request.urlretrieve(URL, tgz)
        subprocess.check_call(["tar", "-xzf", str(tgz), "-C", tmp])
        src = Path(tmp) / "fastfetch-2.64.2"
        apply_patches(src)
        mobile = (src / "src/common/impl/processing_linux.c").read_text()
        if "subprocess unavailable on Apple mobile" not in mobile:
            print("missing Apple-mobile spawn stub", file=sys.stderr)
            return 1
        for token in BANNED_IN_MOBILE_PATCH:
            if token in mobile:
                print(f"unexpected {token} in processing stub", file=sys.stderr)
                return 1
        general = (src / "src/options/general.c").read_text()
        if "WAWONA_APPLE_MOBILE_PRERUN" not in general:
            print("missing preRun guard", file=sys.stderr)
            return 1
        ds = (src / "src/detection/displayserver/displayserver_apple.c").read_text()
        if "WAYLAND_DISPLAY" not in ds:
            print("missing Wayland WM patch", file=sys.stderr)
            return 1
    print("fastfetch patch anchors OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
