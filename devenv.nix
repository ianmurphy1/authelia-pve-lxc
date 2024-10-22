{ pkgs, lib, config, inputs, ... }:

{
  env.REQUESTS_CA_BUNDLE = "/home/ian/.step/certs/root_ca.crt";
  env.ANSIBLE_HOST_KEY_CHECKING = "False";

  # https://devenv.sh/packages/
  packages = [
    pkgs.nixos-generators
  ];

  languages = {
    opentofu.enable = true;
    python = {
      enable = true;
      venv = {
        enable = true;
        requirements = ''
          ansible
        '';
      };
    };
  };

  enterShell = ''
    git --version
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
