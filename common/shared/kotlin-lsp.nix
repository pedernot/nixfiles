{
  autoPatchelfHook,
  fetchurl,
  jdk25,
  lib,
  makeWrapper,
  stdenv,
  stdenvNoCC,
  unzip,
}: let
  version = "262.9593.0";
  sources = {
    x86_64-linux = {
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}.tar.gz";
      hash = "sha256-LZnY4Zj75KqPRIHjd5lyTOlIA7TqEqYLQWBA4/zXzF4=";
    };
    aarch64-darwin = {
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}-aarch64.sit";
      hash = "sha256-a6YCGnBrIeZM7zP34refGHwJEDIHIrstPtBa0RFexD8=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "kotlin-lsp: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "kotlin-lsp";
    inherit version;

    src = fetchurl source;

    nativeBuildInputs =
      [makeWrapper]
      ++ lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [unzip];

    buildInputs =
      [jdk25]
      ++ lib.optionals stdenv.hostPlatform.isLinux [stdenv.cc.cc.lib];

    # JetBrains uses a .sit suffix for the macOS ZIP archives, which Nix cannot
    # detect automatically from the filename.
    unpackCmd = lib.optionalString stdenv.hostPlatform.isDarwin ''unzip "$curSrc"'';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share/kotlin-lsp"
      cp -r \
        bin \
        build.txt \
        lib \
        license \
        modules \
        plugins \
        product-info.json \
        "$out/share/kotlin-lsp/"

      makeWrapper \
        "$out/share/kotlin-lsp/bin/intellij-server" \
        "$out/bin/kotlin-lsp" \
        --set JDK_HOME "${jdk25}/lib/openjdk"

      runHook postInstall
    '';

    meta = {
      description = "Official Kotlin language server";
      homepage = "https://github.com/Kotlin/kotlin-lsp";
      license = lib.licenses.asl20;
      mainProgram = "kotlin-lsp";
      platforms = builtins.attrNames sources;
    };
  }
