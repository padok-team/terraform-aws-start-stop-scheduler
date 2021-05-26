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

  schedules = [{
    tag = { key = "Env", value = "staging" },
    starts = {
      each_weekday_at_6   = "0 6 ? * MON-FRI *",
      each_even_10_minute = "0/20 * ? * * *",
    },
    stops = {
      each_weekday_at_18 = "0 18 ? * MON-FRI *",
      each_odd_10_minute = "10/20 * ? * * *",
    }
  }]

  tags = {
    Green = "IT"
  }

  asg_schedule = false
  rds_schedule = true
}
