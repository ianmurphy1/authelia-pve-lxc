{ pkgs, ... }:
{
  environment.etc."authelia/test.yaml".source = (pkgs.formats.yaml {}).generate "yaml" {
    property = true;
  };

}
