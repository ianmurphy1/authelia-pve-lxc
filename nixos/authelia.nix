{ pkgs, config, lib, ... }:
{
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

  environment.etc."authelia/config.yaml".source = (pkgs.formats.yaml {}).generate "yaml" {
    authentication_backend = {
      file.path = "${config.sops.templates."authelia/users.yaml".path}";
    };
    log = {
      level = "info";
    };
    notifier.filesystem.filename = "/tmp/notifications.txt";
    server.address = "tcp://:9091";
    storage.local.path = "/var/lib/authelia-main/db.sqlite3";
    session = {
      cookies = [{
        name = "authelia_session";
        domain = "authelia.home";
        authelia_url = "https://authelia.home";
        expiration = "1 hour";
        inactivity = "30 minutes";
      }];
    };
    access_control = {
      default_policy = "one_factor";
    };
  };
}
