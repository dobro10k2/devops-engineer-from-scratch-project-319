resource "yandex_vpc_network" "main" {
  name = "bulletin-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "bulletin-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
  route_table_id = yandex_vpc_route_table.main.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "bulletin-nat"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "main" {
  name       = "bulletin-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
