locals {
  domain = lookup(var.account_vars, var.environment).domain
  instance_name = format("%s-%02s", local.instance_fmt, random_integer.instance_id.result)
  cost_center = lookup(var.cost_centers, var.cost_center)
  instance_fmt = lower(format("%s%s%s-%s%s",lower(substr(var.environment, 0, 1)),var.subnet_type == "DMZ" ? "e": "i","ae1", lower(local.cost_center.OU), var.instance_name))
  default_tags = {
    "Environment" = var.environment
    "Name"            = local.instance_name
    "Service Role"    = "EC2 Instance"
  }
  tags = merge(local.cost_center, local.default_tags)
}

data "aws_ami" "ami" {
  most_recent = true
  owners = [lookup(var.ami_filters, var.os_platform).owner]

  filter {
    name   = "name"
    values = [lookup(var.ami_filters, var.os_platform).filter]
  }
}

resource "random_shuffle" "subnet" {
  input        = lookup(lookup(var.account_vars, var.environment),var.subnet_type).subnets
  result_count = 1
}

data "aws_instances" "instances" {
  instance_tags = {
    Name = "${local.instance_fmt}-*"
  }

  instance_state_names = ["running", "stopped"]
}

data "aws_instance" "instance" {
  for_each = toset(data.aws_instances.instances.ids)
  instance_id = each.key
}

resource "random_integer" "instance_id" {
  min = max(concat([0],[for i in data.aws_instance.instance: try(tonumber(regex("\\d*$",i.tags.Name)),0)])...) + 1
  max = max(concat([0],[for i in data.aws_instance.instance: try(tonumber(regex("\\d*$",i.tags.Name)),0)])...) + 1
  lifecycle {
    ignore_changes = [
      min,
      max,
    ]
  }
}

resource "aws_instance" "instance" {
  ami                    = data.aws_ami.ami.id
  instance_type          = lookup(lookup(lookup(var.account_vars, var.environment).instance_sizes, var.os_platform == "RHEL8" ? "linux" : "windows"), lower(var.instance_size))
  subnet_id              = element(random_shuffle.subnet.result,0)
  key_name               = lower(format("%s-%s-key", local.cost_center.OU, var.environment))
  user_data              = var.user_data
  iam_instance_profile   = var.instance_profile
  vpc_security_group_ids = [lookup(lookup(var.account_vars, var.environment),var.subnet_type).security_group]
  tags = local.tags
}


module "bluecat" {
  source    = "app.terraform.io/healthfirst/bluecat/cln"
  version   = "1.15.0"
  hostname  = local.instance_name
  ipAddr    = aws_instance.instance.private_ip
  domain    = local.domain
}
