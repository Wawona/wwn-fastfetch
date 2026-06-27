{
  description = "wwn-fastfetch: Wawona's fastfetch port (App Store–safe in-process on Apple mobile, binaries on macOS/Android) with Wayland WM detection on macOS.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.url = "github:Wawona/wwn-toolchain";
    wwn-toolchain.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.inputs.rust-overlay.follows = "rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay, wwn-toolchain, ... }:
    let
      darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      allSystems = darwinSystems ++ linuxSystems;
      forAll = nixpkgs.lib.genAttrs allSystems;
      inherit (wwn-toolchain.lib) withPlatformVariants baseRegistry mkToolchains;

      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          android_sdk.accept_license = true;
        };
      };

      fastfetchDir = ./dependencies/clients/fastfetch;
    in
    {
      registryFragment = {
        fastfetch = withPlatformVariants {
          android = fastfetchDir + "/android.nix";
          wearos = fastfetchDir + "/wearos.nix";
          ios = fastfetchDir + "/ios.nix";
          tvos = fastfetchDir + "/tvos.nix";
          ipados = fastfetchDir + "/ipados.nix";
          visionos = fastfetchDir + "/visionos.nix";
          watchos = fastfetchDir + "/watchos.nix";
          macos = fastfetchDir + "/macos.nix";
          linux = fastfetchDir + "/linux.nix";
        };
      };

      packages = forAll (system:
        let
          pkgs = pkgsFor system;
          tc = mkToolchains {
            inherit pkgs;
            registry = baseRegistry // self.registryFragment;
          };
          isDarwin = builtins.elem system darwinSystems;
        in
        (if isDarwin then {
          fastfetch-ios = tc.buildForIOS "fastfetch" { };
          fastfetch-macos = tc.buildForMacOS "fastfetch" { };
        } else { }));

      formatter = forAll (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
