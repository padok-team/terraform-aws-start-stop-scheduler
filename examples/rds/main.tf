data "aws_vpc" "default" {
  id = "vpc-4c7f7825"
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


resource "aws_db_instance" "staging" {
  allocated_storage   = 10
  engine              = "postgres"
  engine_version      = "13"
  instance_class      = "db.t3.micro"
  username            = "foo"
  password            = "foobarbaz"
  skip_final_snapshot = true

  tags = {
    "Env"     = "staging",
    "Project" = "GreenIT"
  }
}

resource "aws_db_instance" "prod" {
  allocated_storage   = 10
  engine              = "postgres"
  engine_version      = "13"
  instance_class      = "db.t3.micro"
  username            = "foo"
  password            = "foobarbaz"
  skip_final_snapshot = true

  tags = {
    "Env"     = "prod",
    "Project" = "GreenIT"
  }
}

module "aws_start_stop_scheduler" {
  source = "../.."

  name = "week_stag_rds"

  schedules = [
    {
      name      = "each_20_minute",
      start     = "0/20 * ? * * *",
      stop      = "10/20 * ? * * *",
      tag_key   = "Env",
      tag_value = "staging",
    }
  ]

  tags = {
    Green = "IT"
  }

  asg_schedule = false
  rds_schedule = true
}
