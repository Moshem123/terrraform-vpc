locals {
  private_ips = {for k,v in local.subnet_cidrs: k => cidrhost(v, 10)}
}

resource "aws_key_pair" "terraformUser" {
  key_name   = "terraformUser"
  public_key = file("~/.ssh/terraform.pub")
}

resource "aws_instance" "pingtester" {
  for_each      = toset(var.vpc_cidrs)
  ami           = var.amis[var.region]
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraformUser.key_name
  # private_ip    = cidrhost(local.subnet_cidrs[each.value],10)
  private_ip    = local.private_ips[each.value]
  subnet_id     = aws_subnet.subnet[each.value].id
  
  user_data = <<EOF
#!/bin/bash
#ping -c5 ${cidrhost(tostring(coalesce(setsubtract(var.vpc_cidrs, list(each.value))...)),10)} | tee /var/log/ping-output.log
ping -c5 ${local.private_ips[tostring(coalesce(setsubtract(var.vpc_cidrs, list(each.value))...))]} | tee /var/log/ping-output.log
EOF

  tags = { Name = "PingTester-vpc${index(var.vpc_cidrs, each.value)}" }

  # provisioner "remote-exec" {
  #   inline = [
  #     "ping -c5 ${aws_instance.pingtester[each.value].private_ip}"
  #   ]
  # }
}

resource "aws_security_group" "allow_peering_traffic" {
  for_each    = toset(var.vpc_cidrs)
  name        = "allow_peering_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc[each.value].id

  ingress {
    description = "ICMP from VPC peering traffic"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = var.vpc_cidrs
    # cidr_blocks = setsubtract(var.vpc_cidrs, list(each.value))
  }

  ingress {
    description = "SSH for testing purposes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["31.168.15.126/32"]
    # cidr_blocks = setsubtract(var.vpc_cidrs, list(each.value))
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "allow_peering_traffic" }
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  for_each    = toset(var.vpc_cidrs)
  security_group_id    = aws_security_group.allow_peering_traffic[each.value].id
  network_interface_id = aws_instance.pingtester[each.value].primary_network_interface_id
}