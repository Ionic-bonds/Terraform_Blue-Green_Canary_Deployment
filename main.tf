provider "aws" {
    region = var.region
}

data "aws_availability_zones" "available"{
    state = "available"
    filter {
      name = "opt-in-status"
      values = ["opt-in-not-required"]
    }
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "3.19.0"

    main = "main-vpc"
    cidr = var.vpc_cidr_block

    azs = data.aws_availability_zones.available.names
    private_subnets = slice(var.private_subnets_cidr_blocks, 0, var.private_subnet_count)

    enable_nat_gateway = true 
    enable_vpn_gateway = var.enable_vpn_gateway
  
}

resource "aws_lb" "app" {
  name               = "main-app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [module.lb_security_group.this_security_group_id]
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}