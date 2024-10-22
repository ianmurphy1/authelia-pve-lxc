{ pkgs, config, ... }:
{
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
