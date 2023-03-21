# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0](https://github.com/padok-team/terraform-aws-start-stop-scheduler/compare/v0.2.0...v0.3.0) (2023-03-21)


### Features

* **ec2:** add iam permission to stop instance ([357fbc6](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/357fbc6f04e55d54d7fba28c41aa6f98b576f416))
* **ec2:** init ec2 support ([681a0f2](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/681a0f2691996fb9f8af1616157317bb11d75d85))
* **ec2:** terminate instances rather than stop them ([c25e0cb](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/c25e0cb42e0ff2b9955e4c1936a51ab04c58c516))
* **ec2:** update doc ([d252c11](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/d252c11d4beaef1eeeb9e352fdf1905d7e9047e4))


### Bug Fixes

* **doc:** update config ([f092fc2](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/f092fc20b07e3cfc6340fb1e26834c29dc87ff0a))

## [0.2.0](https://github.com/padok-team/terraform-aws-start-stop-scheduler/compare/v0.1.1...v0.2.0) (2023-01-11)


### ⚠ BREAKING CHANGES

* upgrade to latest aws and terraform version

### Features

* upgrade to latest aws and terraform version ([2ddcd91](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/2ddcd918a9960543948d556a487c370ef2dfc546))


### Miscellaneous Chores

* release 0.2.0 ([5dfbc8c](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/5dfbc8c92b6b09911594546d8ac11da3b782b9dc))

## [0.1.1](https://github.com/padok-team/terraform-aws-start-stop-scheduler/compare/v0.1.0...v0.1.1) (2022-08-12)


### Bug Fixes

* **examples:** add lock state ([8b16d85](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/8b16d8502b79206a179b552c50c627ed372b5396))
* **examples:** set fixed version on example layers ([a8c1068](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/a8c10682371276c9b188d0d278c38601cf5b0f47))
* **versioning:** use ~> syntax for module requirements ([d61e577](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/d61e5778fd960b4291b098d467f2a1fbea94f340))

## 0.1.0 (2022-07-29)


### Features

* add a cron functionnality to trigger the lambda ([6a10fbf](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/6a10fbf1116ce8856326487197ef87d1523d398e))
* add a poc of lambda function ([7f3d768](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/7f3d768ffb46328fe936d7cfd6874eac76264694))
* add lambda permission to schedule rds ([0874871](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/0874871b905de285b24213ecc5efaeb04ebc464f))
* add needed iam permissions for eks nodes ([1e9af20](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/1e9af207c1eb941c23701e7e0c36d97566a9729e))
* add the python code to schedule rds ([db3d543](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/db3d543d3ac8bf34edc6ecf95b9fe809c7a2bcc6))
* cleanup the custom role feature to avoid a target when installing ([5fe63cc](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/5fe63cc6a263dd986b361234ac8a8750d2040c0e))
* **function/scheduler:** add ASG managed by node groups ([a5eda1c](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/a5eda1cc6135c616af5aad59e9a9d81c251193d9))
* **iam:** add an optional variable to use own role ([4604866](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/460486693e3171c10f90e39a46d47709d5915845))
* package the terraform module ([3b8e732](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/3b8e732ec56c181e730e4ed7605d04faef824ea5))


### Bug Fixes

* create cloudwatch group before the lambda to avoid conflict ([32d74a4](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/32d74a4e3f645c15a30b5862527555f25bde35f0))
* set correct iam policies for lambda ([0dd66e7](https://github.com/padok-team/terraform-aws-start-stop-scheduler/commit/0dd66e7be6b996e2c928ed7beca056a535a70ee1))

## [0.5.0] - 2021-05-26

Add support for RDS and simplify schedules syntax.

### Added

- Can now start and stop AWS RDS DB Instance !

### Changed

- New simpler syntax to declare schedule, close to the one used for GCP.

### Fixed

- The Cloudwatch Log Group is now created before the lambda.

## [0.4.0] - 2021-05-26

Cleanup custom role feature, removing the need of a target and adding some documentation.

### Added

- Documentation about custom role

### Changed

- Custom role now use a bool variable to avoid a `tf target`

## [0.3.0] - 2021-05-18

Support custom role

### Added

- Custom role usage

## [0.2.0] - 2021-05-18

First real release with ASG support

### Added

- ASG scheduling
- Documentation
