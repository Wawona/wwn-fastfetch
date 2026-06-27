# fastfetch binary for Android NDK (fork/exec allowed).
args@{
  lib,
  pkgs,
  buildPackages,
  androidToolchain ? (import "${toolchainSrc}/dependencies/toolchains/android.nix" {
    inherit lib pkgs;
  }),
  toolchainSrc ? null,
  ...
}:

let
  inherit (args) lib pkgs buildPackages androidToolchain toolchainSrc;
  fastfetchSrc = import ./common.nix { inherit pkgs; };
in

pkgs.stdenv.mkDerivation {
  pname = "fastfetch-android";
  version = "2.64.2";
  src = fastfetchSrc;

  nativeBuildInputs = with buildPackages; [
    cmake
    ninja
    pkg-config
    python3
  ];

  postPatch = ''
    cp ${./patches/apply-wawona-wayland-macos.py} ./apply-wawona-wayland-macos.py
    python3 apply-wawona-wayland-macos.py
  '';

  configurePhase = ''
    runHook preConfigure
    cmake -S . -B build -G Ninja \
      -DCMAKE_SYSTEM_NAME=Android \
      -DCMAKE_ANDROID_NDK="${androidToolchain.androidNdk}" \
      -DCMAKE_ANDROID_ARCH_ABI=${androidToolchain.androidAbi} \
      -DCMAKE_ANDROID_STL_TYPE=c++_static \
      -DCMAKE_BUILD_TYPE=Release \
      -DBINARY_LINK_TYPE=static \
      -DENABLE_VULKAN=OFF \
      -DENABLE_WAYLAND=OFF
  '';

  buildPhase = ''
    runHook preBuild
    ninja -C build fastfetch
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp build/fastfetch $out/bin/
  '';

  meta = with lib; {
    description = "fastfetch for Android";
    homepage = "https://github.com/fastfetch-cli/fastfetch";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
