{
  stdenv,
  autoPatchelfHook,
  dpkg,
  libuuid,
  libgcc,
}:
stdenv.mkDerivation rec {
  pname = "cbagentd-unwrapped";
  version = "2.15.2";
  commit = "2321702";

  src = ./cb-psc-sensor-${version}-${commit}.x86_64.deb;

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
