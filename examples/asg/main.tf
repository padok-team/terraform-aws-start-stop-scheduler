## Select an ubuntu node image

data "aws_ami" "ubuntu_20_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"]
}

data "aws_vpc" "default" {
  id = "vpc-4c7f7825"
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


resource "aws_launch_template" "launch_template" {
  name_prefix = "start_stop_scheduler"
  description = "Test nodes used for start_stop_scheduler development"
  image_id    = data.aws_ami.ubuntu_20_04.id

  instance_type = "t2.micro"

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "start_stop_scheduler"
      Project = "GreenIT"
    }
  }

}

resource "aws_autoscaling_group" "staging" {
  name_prefix         = "staging"
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  tags = [
    {
      "key"                 = "Env"
      "value"               = "staging"
      "propagate_at_launch" = false
    },
    {
      "key"                 = "Project"
      "value"               = "GreenIT"
      "propagate_at_launch" = false
    }
  ]
}

resource "aws_autoscaling_group" "prod" {
  name_prefix         = "prod"
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  tags = [
    {
      "key"                 = "Env"
      "value"               = "prod"
      "propagate_at_launch" = false
    },
    {
      "key"                 = "Project"
      "value"               = "GreenIT"
      "propagate_at_launch" = false
    }
  ]
}

module "aws_start_stop_scheduler" {
  source = "../.."

  name = "staging_weekday"

  schedules = [{
    tag = { key = "Env", value = "staging" },
    starts = {
      each_weekday_at_6 = "0 6 ? * MON-FRI *"
    },
    stops = {
      each_weekday_at_18 = "0 18 ? * MON-FRI *"
    }
  }]

  tags = {
    Green = "IT"
  }
}
