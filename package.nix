{ lib, pkgs, stdenv, sources, ... }:
let
  dollar = "$";
in stdenv.mkDerivation rec {
  pname = "socket_vmnet";
  version = sources.socket-vmnet-sources.version;
  src = sources.socket-vmnet-sources.src;

  nativeBuildInputs = [
    pkgs.git
    pkgs.gcc
    pkgs.gnumake
    pkgs.coreutils
  ];


  buildInputs =
    lib.optionals stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.vmnet ];

  preConfigure = ''
    export HOME=$TMPDIR

    : Configure git as version control \( required by surfer \)
    git config --global user.email "nixbld@localhost"
    git config --global user.name "nixbld"

    git init
    git add --all
    git commit -m 'nixpkgs'
  '';

  configurePhase = ''
    runHook preConfigure

    : ...

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    make PREFIX=

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    make DESTDIR=$out PREFIX= install.bin install.doc

    runHook postInstall
  '';

  postInstall = ''
    substituteInPlace $out/share/doc/socket_vmnet/README.md \
      --replace-fail "/opt/socket_vmnet" "$out" \
      --replace-fail "/opt/homebrew" "${placeholder "out"}" \
      --replace-fail "\${dollar}{HOMEBREW_PREFIX}" "$out"

    substituteInPlace $out/share/doc/socket_vmnet/launchd/*.plist \
      --replace-fail "/opt/socket_vmnet" "$out"

    substituteInPlace $out/share/doc/socket_vmnet/etc_sudoers.d/socket_vmnet \
      --replace-fail "/opt/socket_vmnet" "$out"
  '';

}
