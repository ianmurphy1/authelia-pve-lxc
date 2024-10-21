data "local_file" "ssh_public_key" {
  filename = "/home/ian/.ssh/id_ed25519.pub"
}

resource "proxmox_virtual_environment_file" "test_file" {
  content_type = "vztmpl"
  datastore_id = "hdd"
  node_name = "pve"

  source_file {
    path = "../generate/result/tarball/nixos-system-x86_64-linux.tar.xz"
    file_name = "authelia-nixos.tar.xz"
  }
}

resource "proxmox_virtual_environment_container" "authelia" {
  node_name = "pve"
  unprivileged = true

  tags = [
    "authelia"
  ]

  operating_system {
    type = "nixos"
    template_file_id = proxmox_virtual_environment_file.test_file.id
  }

  initialization {
    hostname = "authelia"
    user_account {
      keys = [
        trimspace(data.local_file.ssh_public_key.content)
      ]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  disk {
    size = 8
    datastore_id = "local-lvm"
  }

  memory {
    dedicated = 1024 * 1
  }

  network_interface {
    name = "eth0"
    mac_address = "BC:24:11:FF:3B:84"
  }

  features {
    nesting = true
    #keyctl = true
  }
}

data "external" "lxc_ip" {
  program = ["bash", "./scripts/wait_for_ip.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    lxc_id = proxmox_virtual_environment_container.authelia.id
    iname = proxmox_virtual_environment_container.authelia.network_interface[0].name
    token = data.sops_file.secrets.data["pve_token"]
  }
}

output "ip" {
  value = data.external.lxc_ip.result.ip_address
}
