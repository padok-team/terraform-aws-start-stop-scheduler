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

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ASG_SCHEDULE = os.getenv("ASG_SCHEDULE", "true")
RDS_SCHEDULE = os.getenv("RDS_SCHEDULE", "true ")


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
            logger.info(f"Run {action} on {asg}")
            if action == "start":
                asg.start()
            elif action == "stop":
                ## TODO give the option to terminate the instances
                asg.stop()

        response["affected_resources"]["asg"] = [a.name for a in asgs]

    return response


if __name__ == "__main__":
    print(
        lambda_handler(
            {
                "action": "stop",
                "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
            },
            {},
        )
    )
    print("\n------\n")
    print(
        lambda_handler(
            {
                "action": "stop",
                "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
            },
            {},
        )
    )
    print("\n------\n")
    print(
        lambda_handler(
            {
                "action": "start",
                "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
            },
            {},
        )
    )
    print("\n------\n")
    print(
        lambda_handler(
            {
                "action": "start",
                "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
            },
            {},
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
            {"action": "stop", "tag": {"key": "Project", "value": "GreenIT"}}, {}
        )
    )
