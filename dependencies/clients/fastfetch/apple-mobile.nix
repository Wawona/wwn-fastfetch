# fastfetch in-process static archive for Apple mobile (App Store–safe).
{
  lib,
  pkgs,
  buildPackages,
  iosToolchain,
  simulator ? false,
  xcodeUtils ? iosToolchain,
  toolchainSrc ? null,
  fastfetchSrc,
  ...
}:

let
  mobile = (import "${toolchainSrc}/dependencies/toolchains/apple-mobile-platform.nix") {
    inherit iosToolchain simulator;
  };
  appleCmake = import "${toolchainSrc}/dependencies/toolchains/apple-cmake-toolchain.nix";
  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBINARY_LINK_TYPE=static"
    "-DBUILD_TESTS=OFF"
    "-DENABLE_VULKAN=OFF"
    "-DENABLE_SQLITE3=OFF"
    "-DENABLE_IMAGEMAGICK7=OFF"
    "-DENABLE_IMAGEMAGICK6=OFF"
    "-DENABLE_CHAFA=OFF"
    "-DENABLE_DRM=OFF"
    "-DENABLE_EGL=OFF"
    "-DENABLE_GLVND=OFF"
    "-DENABLE_OPENCL=OFF"
    "-DENABLE_RPM=OFF"
    "-DENABLE_DPKG=OFF"
    "-DENABLE_PACMAN=OFF"
    "-DENABLE_I3=OFF"
    "-DENABLE_DCONF=OFF"
    "-DENABLE_DBUS=OFF"
    "-DENABLE_ZFS=OFF"
    "-DENABLE_ZLIB=OFF"
    "-DENABLE_LIBZFS=OFF"
    "-DENABLE_WORDEXP=OFF"
    "-DENABLE_LUA=OFF"
    "-DENABLE_QUICKJS=OFF"
    "-DWAWONA_APPLE_MOBILE=1"
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "fastfetch-apple-mobile";
  version = "2.64.2";

  src = fastfetchSrc;

  __noChroot = true;
  dontConfigure = true;

  nativeBuildInputs = with buildPackages; [
    cmake
    ninja
    pkg-config
    python3
    xcodeUtils.findXcodeScript
  ];

  postPatch = ''
    cp ${./patches/apply-wawona-wayland-macos.py} ./apply-wawona-wayland-macos.py
    cp ${./patches/patch-fastfetch-apple-mobile.py} ./patch-fastfetch-apple-mobile.py
    cp ${./patches/cmake-apple-mobile-sources.snippet} ./cmake-apple-mobile-sources.snippet
    cp ${./patches/processing_apple_mobile.c} ./processing_apple_mobile.c
    cp ${./patches/netif_apple_mobile.c} ./netif_apple_mobile.c
    cp ${./patches/displayserver_apple_mobile.c} ./displayserver_apple_mobile.c
    cp ${./patches/localip_apple_mobile.c} ./localip_apple_mobile.c
    cp ${./patches/sound_apple_mobile.c} ./sound_apple_mobile.c
    python3 apply-wawona-wayland-macos.py
    python3 patch-fastfetch-apple-mobile.py
    cp processing_apple_mobile.c src/common/impl/processing_linux.c
    cp netif_apple_mobile.c src/common/impl/netif_apple.c
    cp displayserver_apple_mobile.c src/detection/displayserver/displayserver_apple.c
    cp localip_apple_mobile.c src/detection/localip/localip_linux.c
    cp sound_apple_mobile.c src/detection/sound/sound_nosupport.c
  '';

  buildPhase = ''
    runHook preBuild

    if [ -z "''${XCODE_APP:-}" ]; then
      XCODE_APP=$(${xcodeUtils.findXcodeScript}/bin/find-xcode || true)
      [ -n "$XCODE_APP" ] && export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
    fi
  '' + (iosToolchain.mkIOSBuildEnv {
    inherit simulator;
    minVersion = mobile.minVersion;
  }) + (appleCmake { inherit iosToolchain simulator; }) + ''
    cmake -S . -B build -G Ninja \
      -DCMAKE_TOOLCHAIN_FILE=$PWD/ios-toolchain.cmake \
      ${lib.concatStringsSep " " cmakeFlags}
    ninja -C build libfastfetch

    OBJ_DIR=build/CMakeFiles/libfastfetch.dir
    $XCODE_CLANG -c src/fastfetch.c \
      -I. -Ibuild -Isrc \
      -arch $IOS_ARCH -isysroot $SDKROOT $APPLE_DEPLOYMENT_FLAG -fPIC -O2 \
      -DFASTFETCH_TARGET_BINARY_NAME=fastfetch -Dmain=fastfetch_main \
      -o fastfetch_main.o

    find "$OBJ_DIR" -name '*.o' -print > objlist.txt
    $DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar rcs libfastfetch.a \
      $(cat objlist.txt) fastfetch_main.o

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp libfastfetch.a $out/lib/
    cat > $out/include/fastfetch.h <<'EOF'
#ifndef WAWONA_FASTFETCH_H
#define WAWONA_FASTFETCH_H
int fastfetch_main(int argc, char *argv[]);
#endif
EOF
  '';

  meta = with lib; {
    description = "fastfetch in-process archive for Apple mobile (App Store safe)";
    homepage = "https://github.com/fastfetch-cli/fastfetch";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
