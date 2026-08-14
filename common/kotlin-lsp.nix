{
  autoPatchelfHook,
  fetchurl,
  jdk25,
  lib,
  makeWrapper,
  stdenv,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = "262.9593.0";

  src = fetchurl {
    url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${finalAttrs.version}/kotlin-server-${finalAttrs.version}.tar.gz";
    hash = "sha256-LZnY4Zj75KqPRIHjd5lyTOlIA7TqEqYLQWBA4/zXzF4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    jdk25
    stdenv.cc.cc.lib
  ];

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
    platforms = ["x86_64-linux"];
  };
})
