{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  environment.systemPackages = with pkgs; [
    python3
  ];

  system.stateVersion = "24.05";
  services.sshd.enable = true;
  users.users.root.password = "nixos";
  services.openssh.settings.PermitRootLogin = lib.mkOverride 999 "yes";
  services.getty.autologinUser = lib.mkOverride 999 "root";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };
  
  services.caddy = {
    enable = true;
    configFile = pkgs.writeText "Caddyfile" ''
      authelia.home:443 {
        tls {
          issuer acme {
            dir https://ca.home/acme/acme/directory
            disable_tlsalpn_challenge
          }
        }
        reverse_proxy 127.0.0.1:9091
      }
    '';
  };

  services.authelia = {
    instances = {
      main = {
        enable = true;
        secrets.manual = true;
        settingsFiles = [
          "/etc/authelia/config.yaml"
        ];
      };
    };
  };

  system.activationScripts.autheliaDirs = lib.stringAfter [ "etc" ] ''
    mkdir -p /etc/authelia
    chown -R authelia-main:authelia-main \
      /etc/authelia
  '';

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  security.pki.certificates = [''
    -----BEGIN CERTIFICATE-----
    MIIBizCCATKgAwIBAgIRAKk5OPRJ23w2j0GTbnjESPYwCgYIKoZIzj0EAwIwJDEM
    MAoGA1UEChMDSWFuMRQwEgYDVQQDEwtJYW4gUm9vdCBDQTAeFw0yNDEwMDIxNDAz
    MzZaFw0zNDA5MzAxNDAzMzZaMCQxDDAKBgNVBAoTA0lhbjEUMBIGA1UEAxMLSWFu
    IFJvb3QgQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATJKuh4t5aL2h5J/+Du
    cXCE2oD6A9Vldnca6ULUepoI9ahGINtwv7fAPGfMMnvtuXjVQ3bMDBj50RHLJOM0
    zsqXo0UwQzAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBATAdBgNV
    HQ4EFgQU+3kOFZmQ2elFg7OvFlmUXJulyo0wCgYIKoZIzj0EAwIDRwAwRAIgK5/U
    /ecieFTnhkQw1XWzlINkmcozWboYyHDZTeKNdYECIAo7AzOpkQDA/PnP6wAYdNfr
    NjtqY45e3g98ykzfuRqd
    -----END CERTIFICATE-----
  ''];
}
