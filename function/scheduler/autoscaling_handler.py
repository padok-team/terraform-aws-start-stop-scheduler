# -*- coding: utf-8 -*-

"""
Autoscaling instances scheduler.

Source: https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start/blob/master/package/scheduler/autoscaling_handler.py
"""
import logging
from typing import Dict, Iterator, List

import boto3

from botocore.exceptions import ClientError

import boto3

logger = logging.getLogger()


class AutoscalingScheduler(object):
    """Abstract autoscaling scheduler in a class."""

    def __init__(self) -> None:
        """Initialize autoscaling scheduler."""
        self.ec2 = boto3.client("ec2")
        self.asg = boto3.client("autoscaling")

    def stop(self, asg_name: str, terminate: bool = True) -> None:
        """Aws autoscaling suspend function.

        Suspend autoscaling group and stop its instances
        with defined tag.

        :param str asg_name:
            Name of the ASG to stop
        """
        instance_id_list = self.list_instances(asg_name)

        try:
            self.asg.suspend_processes(AutoScalingGroupName=asg_name)
            logger.info("Suspend autoscaling group {0}".format(asg_name))
        except ClientError as exc:
            # ec2_exception("instance", asg_name, exc)
            logger.warn(exc)

        # Stop autoscaling instance
        for instance_id in instance_id_list:
            try:
                if terminate:
                    self.ec2.terminate_instances(InstanceIds=[instance_id])
                    logger.info(
                        "Terminate autoscaling instances {0}".format(instance_id)
                    )
                else:
                    self.ec2.stop_instances(InstanceIds=[instance_id])
                    logger.info("Stop autoscaling instances {0}".format(instance_id))
            except ClientError as exc:
                # ec2_exception("autoscaling group", instance_id, exc)
                logger.warn(exc)

    def start(self, asg_name: str, terminate: bool = True) -> None:
        """Aws autoscaling resume function.

        Resume autoscaling group and start its instances
        with defined tag.

        :param str asg_name:
            Name of the ASG to start

        """
        instance_id_list = self.list_instances(asg_name)
        instance_running_ids = []

        # Start autoscaling instance
        if not (terminate):
            for instance_id in instance_id_list:
                try:
                    self.ec2.start_instances(InstanceIds=[instance_id])
                    logger.info("Start autoscaling instances {0}".format(instance_id))
                except ClientError as exc:
                    # ec2_exception("instance", instance_id, exc)
                    logger.warn(exc)
                else:
                    instance_running_ids.append(instance_id)

            # self.waiter.instance_running(instance_ids=instance_running_ids)

        try:
            self.asg.resume_processes(AutoScalingGroupName=asg_name)
            logger.info("Resume autoscaling group {0}".format(asg_name))
        except ClientError as exc:
            # ec2_exception("autoscaling group", asg_name, exc)
            logger.warn(exc)

    def list_groups(self, tag_key: str, tag_value: str) -> List[str]:
        """Aws autoscaling list function.

        List name of all autoscaling groups with
        specific tag and return it in list.

        :param str tag_key:
            Aws tag key to use for filter resources
        :param str tag_value:
            Aws tag value to use for filter resources

        :return list asg_name_list:
            The names of the Auto Scaling groups
        """
        asg_name_list = []
        paginator = self.asg.get_paginator("describe_auto_scaling_groups")

        for page in paginator.paginate():
            for group in page["AutoScalingGroups"]:
                for tag in group["Tags"]:
                    if tag["Key"] == tag_key and tag["Value"] == tag_value:
                        asg_name_list.append(group["AutoScalingGroupName"])
        return asg_name_list

    def list_instances(self, asg_name: str) -> Iterator[str]:
        """Aws autoscaling instance list function.

        List name of all instances in the autoscaling group
        and return it in list.

        :param list asg_name:
            The name of the Auto Scaling group.

        :yield Iterator[str]:
            The names of the instances in Auto Scaling group.
        """
        if not asg_name:
            return iter([])
        paginator = self.asg.get_paginator("describe_auto_scaling_groups")

        for page in paginator.paginate(AutoScalingGroupNames=[asg_name]):
            for scalinggroup in page["AutoScalingGroups"]:
                for instance in scalinggroup["Instances"]:
                    yield instance["InstanceId"]
