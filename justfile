build:
  cd ./generate && \
    nix build .#authelia

deploy:
  cd ./terraform && \
    tofu plan -var-file ./variable.tfvars -out plan && \
    tofu apply -auto-approve plan

destroy:
  cd ./terraform && \
    tofu apply -auto-approve \
      -var-file ./variable.tfvars \
      -destroy

secrets:
  lxcsecrets

update:
  cd ./nixos && \
  nix flake update && \
  nixos-rebuild switch --flake .#authelia --target-host root@${IP}

test:
  cd ./ansible && \
    ansible-playbook -i inventory/proxmox.yaml update.yaml


doit:
  just build deploy secrets update
