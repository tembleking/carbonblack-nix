{
  buildFHSEnv,
  writeShellScript,
  cbagentd-unwrapped,
}:
buildFHSEnv {
  pname = "cbagentd";
  version = cbagentd-unwrapped.version;
  targetPkgs = pkgs: [
    cbagentd-unwrapped
    pkgs.gnupg
  ];

  extraBwrapArgs = [
    "--ro-bind /home /home"
    "--tmpfs /opt"
    "--tmpfs /var"
    "--tmpfs /var/run"
  ];

  runScript = writeShellScript "cbagentd" ''
    registration_code="$1"
    shift

    echo ">> Copying the contents from the derivation to the writable tmpfs"
    cp -r -L ${cbagentd-unwrapped}/var/carbonblack/* /

    echo Registering blades
    if [ -f /opt/carbonblack/psc/blades/E51C4A7E-2D41-4F57-99BC-6AA907CA3B40/bladeConfigure.sh ]; then
      /opt/carbonblack/psc/blades/E51C4A7E-2D41-4F57-99BC-6AA907CA3B40/bladeConfigure.sh
    fi
    if [ -f /opt/carbonblack/psc/blades/40E797FD-4322-4D33-8E8C-EF697F4C2323/bladeConfigure.sh ]; then
      /opt/carbonblack/psc/blades/40E797FD-4322-4D33-8E8C-EF697F4C2323/bladeConfigure.sh
    fi
    if [ -f /var/opt/carbonblack/psc/cfg.ini.dpkg-dist ]; then
      /opt/carbonblack/psc/bin/mergeConfigs.sh /var/opt/carbonblack/psc/cfg.ini.dpkg-dist /var/opt/carbonblack/psc/cfg.ini
      rm -f /var/opt/carbonblack/psc/cfg.ini.dpkg-dist
    fi

    echo ">> Installing OpenSSL fips"
    /opt/carbonblack/psc/bin/install_openssl_fips.sh

    echo ">> Decoding registration code"
    /opt/carbonblack/psc/bin/cbagentd --stdout -d "$registration_code"

    echo ">> Registering device"
    /opt/carbonblack/psc/bin/cbagentd --stdout -r

    echo ">> Executing cbagentd"
    exec /opt/carbonblack/psc/bin/cbagentd "$@"
  '';

  meta.mainProgram = "cbagentd";
}
