# wwn-fastfetch

Wawona's port of [fastfetch](https://github.com/fastfetch-cli/fastfetch) — cross-compiled
with [wwn-toolchain](https://github.com/Wawona/wwn-toolchain) for **macOS, Apple mobile,
and Android**. Upstream 2.64.2 is fetched at build time and patched in-place (patch-overlay
model, same as `wwn-zsh` / `wwn-weston`).

## Wawona fork change

On macOS, when `WAYLAND_DISPLAY` is set, fastfetch reports the compositor as **Wayland**
(with optional `XDG_CURRENT_DESKTOP` pretty name) instead of only "Quartz Compositor".
This makes nested Wayland sessions inside Wawona obvious in `fastfetch` output.

Patch: `dependencies/clients/fastfetch/patches/apply-wawona-wayland-macos.py`

## App Store compliance (Apple mobile)

Per [WWN-MCP knowledge on iOS shell compliance](https://github.com/Wawona/WWN-MCP/blob/main/knowledge/zsh-ios-appstore-compliance.md), Apple mobile builds:

- Ship as **`libfastfetch.a`** with entry point **`fastfetch_main`** (no separate Mach-O in the bundle).
- **Never** `fork`, `exec`, `posix_spawn`, or `system()` — subprocess-based module detection is stubbed on iOS/iPadOS/tvOS/watchOS (`patch-fastfetch-apple-mobile.py`).
- CI: `.github/scripts/verify-fastfetch-ios-patches.py` checks patch anchors against pristine 2.64.2.

Android uses a normal `fastfetch` binary (fork allowed, like `wwn-zsh` Android).

## Nix registry

| Attribute | Outputs |
|-----------|---------|
| `fastfetch` | `libfastfetch.a` + `fastfetch_main` (Apple mobile); `fastfetch` binary (macOS/Android); nixpkgs ref (Linux) |

## Platform coverage

| Platform | Recipe | Notes |
|----------|--------|-------|
| iOS / iPadOS / tvOS / watchOS / visionOS | `apple-mobile.nix` | In-process archive |
| macOS | `macos.nix` | Standalone binary + `libfastfetch.a` |
| Android / Wear OS | `android.nix` | NDK binary |
| Linux | `linux.nix` | nixpkgs `fastfetch` reference |

## Use in a flake

```nix
inputs.wwn-fastfetch.url = "github:Wawona/wwn-fastfetch";

registry = wwn-toolchain.lib.baseRegistry // wwn-fastfetch.registryFragment;
```

## Standalone build

```sh
nix build .#fastfetch-ios
nix build .#fastfetch-macos
```

## Layout

```
dependencies/clients/fastfetch/
  patches/           # apply at build time (not vendored upstream tree)
  apple-mobile.nix   # iOS family in-process archive
  macos.nix
  android.nix
```

## Migration note

Supersedes the org fork `github.com/Wawona/fastfetch` (dev branch with the same Wayland
WM tweak). New work lives here under the `wwn-*` patch-overlay model.

## License

MIT for Wawona packaging (see `LICENSE`). fastfetch upstream is MIT; sources are downloaded at build time.
