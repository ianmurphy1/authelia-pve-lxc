{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    secrets = {
      jwt = {
        owner = config.systemd.services.authelia-main.serviceConfig.User;
      };
      storage_key = {
        owner = config.systemd.services.authelia-main.serviceConfig.User;
      };
      session_secret = {
        owner = config.systemd.services.authelia-main.serviceConfig.User;
      };
      user_password = {
        owner = config.systemd.services.authelia-main.serviceConfig.User;
      };
      lldap_admin_pass = {
        owner = config.systemd.services.lldap.serviceConfig.User;
      };
      lldap_jwt = {
        owner = config.systemd.services.lldap.serviceConfig.User;
      };
    };
  };

  sops.templates."authelia/users.yaml" = {
    owner = "authelia-main";
    file = (pkgs.formats.yaml {}).generate "yaml" {
      users = {
        ian = {
          disabled = false;
          displayname = "ian";
          password = "${config.sops.placeholder.user_password}";
          email = "ian@home.com";
          groups = [ "admin" ];
        };
      };
    };
  };

  system.stateVersion = "24.11";
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
        secrets.jwtSecretFile = config.sops.secrets.jwt.path;
        secrets.sessionSecretFile = config.sops.secrets.session_secret.path;
        secrets.storageEncryptionKeyFile = config.sops.secrets.storage_key.path;
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

  networking.firewall.allowedTCPPorts = [ 80 443 17170 ];
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

  environment.etc."authelia/providers.yaml".source = (pkgs.formats.yaml { }).generate "YAML" {
    identity_providers = {
      oidc = {
        clients = [{
          client_id = "argocd_client_id";
          client_name = "ArgoCD";
        }];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    python3
    sops
    vim
  ];

  environment.sessionVariables = {
    EDITOR = "vim";
  };
  users.users.lldap = {
    uid = 99;
    group = "lldap";
  };

  users.groups.lldap = {
    gid = 99;
  };
}
