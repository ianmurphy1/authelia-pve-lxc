{ pkgs, config, ... }:
{
  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "cn=home";
      environment = {
        LLDAP_JWT_SECRET_FILE = config.sops.secrets.lldap_jwt.path;
        LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets.lldap_user_pass.path;
      };
    };
  };
}
