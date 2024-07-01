{ lib
, stdenv
, fetchFromGitHub
, cacert
, cmake
, cmakerc
, fmt
, git
, gzip
, meson
, ninja
, openssh
, python3
, zip
, zstd
, extraRuntimeDeps ? []
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "vcpkg-tool";
  version = "2024-06-10";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "vcpkg-tool";
    rev = finalAttrs.version;
    hash = "sha256-TGRTzUd1FtErD+h/ksUsUm1Rhank9/yVy06JbAgEEw0=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    cmakerc
    fmt
  ];

  patches = [
    ./change-lock-location.patch
  ];

  cmakeFlags = [
    "-DVCPKG_DEPENDENCY_EXTERNAL_FMT=ON"
    "-DVCPKG_DEPENDENCY_CMAKERC=ON"
  ];


  # vcpkg needs two directories to write to that is independent of installation directory.
  # Since vcpkg already creates $HOME/.vcpkg/ we use that to create a root where vcpkg can write into.
  passAsFile = [ "vcpkgWrapper" ];
  vcpkgWrapper = let
    # These are the most common binaries used by vcpkg
    # Extra binaries can be added via overlay when needed
    runtimeDeps = [
      cacert
      cmake
      git
      gzip
      meson
      ninja
      openssh
      python3
      zip
      zstd
    ] ++ extraRuntimeDeps;
  in ''
    vcpkg_writable_path="$HOME/.vcpkg/root/"

    export PATH="${lib.makeBinPath runtimeDeps}''${PATH:+":$PATH"}"

    "${placeholder "out"}/bin/vcpkg" \
      --x-downloads-root="$vcpkg_writable_path"/downloads \
      --x-buildtrees-root="$vcpkg_writable_path"/buildtrees \
      --x-packages-root="$vcpkg_writable_path"/packages \
      "$@"
  '';

  postFixup = ''
    mv "$out/bin/vcpkg" "$out/bin/.vcpkg-wrapped"
    install -Dm555 "$vcpkgWrapperPath" "$out/bin/vcpkg"
  '';

  meta = {
    description = "Components of microsoft/vcpkg's binary";
    mainProgram = "vcpkg";
    homepage = "https://github.com/microsoft/vcpkg-tool";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ guekka gracicot ];
    platforms = lib.platforms.all;
  };
})
