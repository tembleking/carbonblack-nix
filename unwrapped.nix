{
  stdenv,
  autoPatchelfHook,
  dpkg,
  libuuid,
  libgcc,
  requireFile,
}:
stdenv.mkDerivation rec {
  pname = "cbagentd-unwrapped";
  version = "2.16.0";
  commit = "2566828";

  # nix store add --mode flat --hash-algo sha256 <filename.deb>
  src = requireFile {
    name = "cb-psc-sensor-${version}-${commit}.x86_64.deb";
    url = "https://drive.google.com/drive/folders/1_gsIKvP7R4Nve9vy3DqHCykBgMsPbCGD";
    # nix hash file --sri --type sha256 <filename.deb>
    sha256 = "sha256-42tgwnzhfTlAdOx014RwA6+sDbjW2K0ulJsTvwOnAEw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    libuuid.lib
    libgcc.lib
  ];

  installPhase = ''
    mkdir -p $out/var/carbonblack
    dpkg -X $src $out/var/carbonblack
  '';

  passthru = {
    inherit commit;
  };
}
