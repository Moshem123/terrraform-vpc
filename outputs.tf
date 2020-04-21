output "vpc_ids" {
  value = {
    for each in aws_vpc.vpc :
    each.id => each.cidr_block
  }
}
output "instances_data" {
  value = {
    for each in aws_instance.pingtester :
    each.id => each.public_ip
  }
}