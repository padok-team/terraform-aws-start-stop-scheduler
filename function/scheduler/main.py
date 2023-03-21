"""
Start or stop AWS resources, based on their tags.

I used a lot of code from https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start/
"""

import logging
import os
import boto3

from time import sleep
from typing import List, Dict

from scheduler.autoscaling import list_asg_by_tags
from scheduler.rds import list_rds_by_tags
from scheduler.ec2 import list_ec2_by_tags

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ASG_SCHEDULE = os.getenv("ASG_SCHEDULE", "true")
RDS_SCHEDULE = os.getenv("RDS_SCHEDULE", "true")
EC2_SCHEDULE = os.getenv("EC2_SCHEDULE", "true")


def lambda_handler(event, context):
    """
    Stop and start AWS resources:
    - AutoScalingGroups

    :param event: The event dict that contains the parameters sent when the function
                  is invoked.
    :param context: The context in which the function is called.
    :return: The result of the specified action.
    """
    sts = boto3.client("sts")
    logger.info(f"Running function as {sts.get_caller_identity().get('Arn')}")

    logger.info(f"Event: {event}")
    logger.info(f"Context: {context}")

    action = event["action"]

    if action not in ["start", "stop"]:
        raise Exception(
            f"Action '{action}' is not supported. Choose one of [start, stop]."
        )

    tag = event["tag"]

    response = {"action": action, "tag": tag, "affected_resources": {}}

    if ASG_SCHEDULE == "true":

        logger.info(f"Select autoscaling groups with tags {tag['key']}={tag['value']}")
        asgs = list_asg_by_tags(tag["key"], tag["value"])

        logger.info(f"Run {action} function on {len(asgs)} autoscaling groups")

        for asg in asgs:
            logger.info(f"Run {action} on {asg.name}")
            if action == "start":
                asg.start()
            elif action == "stop":
                ## TODO give the option to terminate the instances
                asg.stop()

        response["affected_resources"]["asg"] = [a.name for a in asgs]

    if RDS_SCHEDULE == "true":

        logger.info(f"Select RDS instances with tags {tag['key']}={tag['value']}")
        rds_list = list_rds_by_tags(tag["key"], tag["value"])

        logger.info(f"Run {action} function on {len(rds_list)} rds instances")

        for rds in rds_list:
            logger.info(f"Run {action} on {rds.db_id}")
            if action == "start":
                rds.start()
            elif action == "stop":
                rds.stop()

        response["affected_resources"]["rds"] = [r.db_id for r in rds_list]

    if EC2_SCHEDULE == "true":

        logger.info(f"Select EC2 instances with tags {tag['key']}={tag['value']}")
        ec2_list = list_ec2_by_tags(tag["key"], tag["value"])

        logger.info(f"Run {action} function on {len(ec2_list)} ec2 instances")
        for ec2 in ec2_list:
            logger.info(f"Run {action} on {ec2.instance_id}")
            if action == "stop":
                ec2.stop()

        response["affected_resources"]["ec2"] = [r.instance_id for r in ec2_list]

    return response


if __name__ == "__main__":
    print("\n------\n")
    print(
        lambda_handler(
            {"action": "stop", "tag": {"key": "Project", "value": "GreenIT"}}, {}
        )
    )
    print("\n------\n")
    print(
        lambda_handler(
            {"action": "stop", "tag": {"key": "Project", "value": "GreenIT"}}, {}
        )
    )
    print("\n------\n")
    print(
        lambda_handler(
            {"action": "start", "tag": {"key": "Project", "value": "GreenIT"}}, {}
        )
    )
    print("\n------\n")
    print(
        lambda_handler(
            {"action": "start", "tag": {"key": "Project", "value": "GreenIT"}}, {}
        )
    )
