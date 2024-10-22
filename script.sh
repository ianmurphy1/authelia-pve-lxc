#!/usr/bin/env bash
set -e #x

# Remove existing SSH key from known_hosts file
# ssh config is setup to accept new keys from
# 192.168.1.45/24 IPs
sed -i '/^192.168.1.45/d' ~/.ssh/known_hosts

AGE_KEY=$(ssh -T root@192.168.1.45 <<'EOL'
  mkdir -p ~/.config/sops/age
  nix-channel --update
  nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key" > ~/.config/sops/age/keys.txt
  nix-shell -p age --run "age-keygen -y ~/.config/sops/age/keys.txt"
  nixos-generate-config >/dev/null 2>&1
EOL
)

key="${AGE_KEY}" yq -i '.keys[1] |= env(key)' ./.sops.yaml

sops updatekeys -y ./secrets.yaml

cp ./secrets.yaml ./nixos

scp -q root@192.168.1.45:/etc/nixos/hardware-configuration.nix ./nixos
