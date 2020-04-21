resource "aws_vpc" "vpc" {
  for_each             = toset(var.vpc_cidrs)
  cidr_block           = each.value
  enable_dns_hostnames = true
  tags                 = { Name = "Company0${index(var.vpc_cidrs, each.value) + 1}" }
}

resource "aws_internet_gateway" "gw" {
  for_each = toset(var.vpc_cidrs)
  vpc_id   = aws_vpc.vpc[each.value].id
  tags     = { Name = "Company0${index(var.vpc_cidrs, each.value) + 1}-IGW" }
}

resource "aws_subnet" "subnet" {
  for_each                = toset(var.vpc_cidrs)
  vpc_id                  = aws_vpc.vpc[each.value].id
  cidr_block              = cidrsubnet(each.value, 8, 1)
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]
  tags       = { Name = "Company0${index(var.vpc_cidrs, each.value) + 1}-Public" }
}

resource "aws_vpc_peering_connection" "cross_vpc_traffic" {
  peer_vpc_id = aws_vpc.vpc[var.vpc_cidrs[1]].id
  vpc_id      = aws_vpc.vpc[var.vpc_cidrs[0]].id
  auto_accept = true
  tags        = { Name = "cross-vpc-traffic" }
}

resource "aws_route_table" "rt" {
  for_each = toset(var.vpc_cidrs)
  vpc_id = aws_vpc.vpc[each.value].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[each.value].id
  }

  route {
    cidr_block = tostring(coalesce(setsubtract(var.vpc_cidrs, list(each.value))...))
    vpc_peering_connection_id = aws_vpc_peering_connection.cross_vpc_traffic.id
  }

  tags = { Name = "Company0${index(var.vpc_cidrs, each.value) + 1}-Public" }
}

resource "aws_route_table_association" "assoc" {
  for_each = toset(var.vpc_cidrs)
  subnet_id      = aws_subnet.subnet[each.value].id
  route_table_id = aws_route_table.rt[each.value].id
}