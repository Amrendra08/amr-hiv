provider "aws" {
  region = var.aws_region
}

data "aws_vpcs" "foo" {}

data "aws_vpc" "foo" {
  count = length(data.aws_vpcs.foo.ids)
  id    = tolist(data.aws_vpcs.foo.ids)[count.index]
}

resource "aws_subnet" "private_subnet_01" {
  count      = length(data.aws_vpcs.foo.ids)
  vpc_id     = data.aws_vpc.foo[count.index].id
  cidr_block = var.private_subnet_1

  tags = {
    Name = "private_subnet_1"
  }
}

data "aws_subnets" "example" {}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}

resource "aws_security_group" "tf_public_sg" {
  name        = "prod-web-servers-sg"
  description = "Used for access to the public instances"
  count       = length(data.aws_vpcs.foo.ids)
  vpc_id      = data.aws_vpc.foo[count.index].id

  #HTTPS

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // ingress {
  //   from_port   = 22
  //   to_port     = 22
  //   protocol    = "tcp"
  //   cidr_blocks = ["0.0.0.0/0"]
  // }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "amrendra-ec2" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet_01[0].id
  count = var.instance-count
  // user_data = data.template_file.user-init.*.rendered[count.index]
  //   count = length(data.aws_vpcs.foo.ids)

  tags = {
    Name = join("-", ["prod-web-server", count.index + 1])
  }
  vpc_security_group_ids = [aws_security_group.tf_public_sg[0].id]
  key_name               = aws_key_pair.master-key.key_name
}

resource "aws_key_pair" "master-key" {
  key_name   = "amrendra"
  public_key = file("id_rsa.pub")
}


resource "aws_lb" "nlb" {
  name               = "amrendra-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets = [for r in data.aws_subnet.example : r.id if r.id != aws_subnet.private_subnet_01[0].id]
  // count = 3

  enable_deletion_protection = false

}

resource "aws_lb_target_group" "web-server" {
  name     = "web-server-tg"
  port     = 80
  protocol = "TCP"
  count       = length(data.aws_vpcs.foo.ids)
  vpc_id      = data.aws_vpc.foo[count.index].id  
}

resource "aws_lb_target_group_attachment" "web-server-instances" {
  target_group_arn = aws_lb_target_group.web-server[count.index].arn
  target_id        = aws_instance.amrendra-ec2[0].id
  count       = length(data.aws_vpcs.foo.ids)
  port             = 80
}

resource "aws_lb_target_group_attachment" "web-server-instances-2" {
  target_group_arn = aws_lb_target_group.web-server[count.index].arn
  target_id        = aws_instance.amrendra-ec2[1].id
  count       = length(data.aws_vpcs.foo.ids)
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  count       = length(data.aws_vpcs.foo.ids)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-server[0].arn
  }
}

resource "aws_route_table" "private_rt" {
  count       = length(data.aws_vpcs.foo.ids)
  vpc_id      = data.aws_vpc.foo[count.index].id

  route = []  
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_subnet_01[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
  count       = length(data.aws_vpcs.foo.ids)
}
