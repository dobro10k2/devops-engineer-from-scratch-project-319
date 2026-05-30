data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

resource "yandex_compute_instance" "master" {
  name        = "k3s-master"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
    user-data = templatefile("${path.module}/cloud-init/master.yaml", {
      k3s_token = random_password.k3s_token.result
    })
  }
}

resource "yandex_compute_instance" "worker" {
  count       = 2 # Создаем 2 рабочие ноды
  name        = "k3s-worker-${count.index + 1}"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = false # Белые IP не нужны, доступ через NAT-шлюз
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
    user-data = templatefile("${path.module}/cloud-init/worker.yaml", {
      k3s_token      = random_password.k3s_token.result
      master_priv_ip = yandex_compute_instance.master.network_interface[0].ip_address
    })
  }
}
