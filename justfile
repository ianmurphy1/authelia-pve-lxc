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
  ./script.sh

update:
  cd ./nixos && \
  nixos-rebuild switch --flake .#authelia --target-host root@192.168.1.45

test:
  cd ./ansible && \
    ansible-playbook -i inventory/proxmox.yaml update.yaml


doit:
  just build deploy secrets update
