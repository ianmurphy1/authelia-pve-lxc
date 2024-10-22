{ pkgs, ... }:
{
  environment.etc."authelia/user_db.yaml".source = (pkgs.formats.yaml {}).generate "yaml" {
    property = true;
  };

}
