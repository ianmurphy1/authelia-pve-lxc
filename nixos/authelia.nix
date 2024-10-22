{ pkgs, config, lib, ... }:
{
  sops.secrets = {
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
    authelia_oidc_private_key = {
      owner = config.systemd.services.authelia-main.serviceConfig.User;
    };
    hmac_secret = {
      owner = config.systemd.services.authelia-main.serviceConfig.User;
    };
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
          "${config.sops.templates."authelia/providers.yaml".path}"
        ];
        environmentVariables = {
          X_AUTHELIA_CONFIG_FILTERS = "template";
        };
      };
    };
  };

  environment.etc."authelia/config.yaml".source = (pkgs.formats.yaml {}).generate "yaml" {
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
    authentication_backend = {
      file.path = config.sops.templates."authelia/users.yaml".path;
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
          groups = [
            "admin"
            "argocd-admin"
          ];
        };
      };
    };
  };
}
