{
  description = "Carbon Black Cloud Sensor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      name = "cbagentd";
      version = "2.15.2";
      commit = "2321702";

      cbagentd =
        with pkgs;
        stdenv.mkDerivation {
          inherit name version;

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
            mkdir -p $out/var/run/ $out/opt/carbonblack $out/var/opt/carbonblack $out/etc
          '';
        };
      cbagentdFHS =
        with pkgs;
        buildFHSEnv {
          inherit name;
          targetPkgs = pkgs: [
            cbagentd
            gnupg
          ];

          extraBwrapArgs = [
            "--ro-bind /home /home"
            "--tmpfs /opt/carbonblack"
            "--tmpfs /var/opt/carbonblack"
            "--tmpfs /var/opt/carbonblack/psc/log/"
            "--tmpfs /var/opt/carbonblack/psc/pkgs/"
            "--tmpfs /var/run"
          ];

          runScript = writeShellScript "cbagentd" ''
            registration_code="$1"
            shift

            echo ">> Copying the contents from the derivation to the writable tmpfs"
            cp -r -L /var/carbonblack/* /

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
        };
    in
    with pkgs;
    {
      defaultPackage.${system} = cbagentdFHS;
      formatter.${system} = alejandra;

      nixosModules.cbagentd =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (lib) mkEnableOption mkOption mkIf;
          cfg = config.services.cbagentd;
        in
        {
          options.services.cbagentd = {
            enable = mkEnableOption "cbagentd";
            code = mkOption {
              type = lib.types.str;
              description = ''
                The company code needed for carbon black operation.
              '';
            };
          };

          config = mkIf cfg.enable {
            systemd.services.cbagentd = {
              description = "Carbon Black Predictive Security Cloud Endpoint Agent.";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Environment = [
                  "OPENSSL_CONF=${cbagentd}/var/opt/carbonblack/psc/ssl/openssl.cnf"
                  "OPENSSL_MODULES=${cbagentd}/opt/carbonblack/psc/lib"
                ];
                ExecStart = "${cbagentdFHS}/bin/cbagentd ${cfg.code} --foreground --stdout";
                KillMode = "process";
                Type = "simple";
                Restart = "on-failure";
                RestartSec = 10;
                Umask = 77;
              };
            };
          };
        };
    };
}
