output "security_group" {
  value = aws_security_group.tf_public_sg[0].name
}

output "default_vpc" {
  value = data.aws_vpc.foo[0].id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet_01[0].id
}

output "server_ids" {
  value = join(", ", aws_instance.amrendra-ec2.*.id)
}

output "servers_private_ips" {
  value = join(", ", aws_instance.amrendra-ec2.*.private_ip)
}

output "servers_instance_type" {
  value = join(", ", aws_instance.amrendra-ec2.*.instance_type)
}

output "nlb" {
  value = aws_lb.nlb.dns_name
}