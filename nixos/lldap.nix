{ pkgs, config, lib, ... }:
{
  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "cn=home";
    };
  };
  systemd.services.lldap = {
    serviceConfig = {
      User = "lldap";
      DynamicUser = lib.mkForce false;
    };
    environment = {
      LLDAP_JWT_SECRET_FILE = config.sops.secrets.lldap_jwt.path;
      LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets.lldap_admin_pass.path;
    };
  };
}
