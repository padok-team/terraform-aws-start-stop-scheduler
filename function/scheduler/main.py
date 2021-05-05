"""
Start or stop AWS resources, based on their tags.

I used a lot of code from https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start/
"""

import logging
import boto3

from time import sleep
from typing import List, Dict

from scheduler.autoscaling_handler import AutoscalingScheduler

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

SUPPORTED_RESOURCES_TYPES = ["autoScalingGroup"]


def lambda_handler(event, context):
    """
    Stop and start AWS resources:
    - AutoScalingGroups

    :param event: The event dict that contains the parameters sent when the function
                  is invoked.
    :param context: The context in which the function is called.
    :return: The result of the specified action.
    """
    client = boto3.client("sts")
    logger.info(f"Running function as {client.get_caller_identity().get('Arn')}")

    logger.info(f"Event: {event}")
    logger.info(f"Context: {context}")

    action = event["action"]
    tag = event["tag"]
    # tag_filter = transform_tag_to_tag_filter(tag)

    logger.info(f"Run {action} function on autoscaling groups")
    asg_scheduler = AutoscalingScheduler()

    asgs = asg_scheduler.list_groups(tag["key"], tag["value"])

    for asg in asgs:
        logger.info(f"Run {action} on {asg}")

        if action == "start":
            asg_scheduler.start(asg)
        elif action == "stop":
            ## TODO give the option to terminate the instances
            asg_scheduler.stop(asg)
        else:
            raise Exception(
                f"Action '{action}' is not supported. Choose one of [start, stop]."
            )

    response = {"action": action, "tag": tag, "affected_resources": {"asg": asgs}}
    return response


def start():
    pass


def stop():
    pass


def transform_tag_to_tag_filter(tag: Dict[str, str]) -> List[Dict[str, List[str]]]:
    return {"Key": tag["key"], "Values": [tag["value"]]}


# Does not work for ASG
# https://serverfault.com/questions/936559/searching-aws-autoscalinggroup-resources-by-tags
# def get_resources(resource_type: str, tags: List[Dict[str, str]]):
#     client = boto3.client("resourcegroupstaggingapi")
#     paginator = client.get_paginator("get_resources")
#     page_iterator = paginator.paginate(
#         TagFilters=tags, ResourceTypeFilters=[resource_type]
#     )
#     for page in page_iterator:
#         for resource_tag_map in page["ResourceTagMappingList"]:
#             yield resource_tag_map["ResourceARN"]

if __name__ == "__main__":
    lambda_handler(
        {
            "action": "stop",
            "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
        },
        {},
    )
    print("\n------\n")
    lambda_handler(
        {
            "action": "stop",
            "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
        },
        {},
    )
    print("\n------\n")
    lambda_handler(
        {
            "action": "start",
            "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
        },
        {},
    )
    print("\n------\n")
    lambda_handler(
        {
            "action": "start",
            "tag": {"key": "start_stop_scheduler_group", "value": "test_asg_2"},
        },
        {},
    )
    print("\n------\n")
    lambda_handler(
        {"action": "start", "tag": {"key": "Project", "value": "GreenIT"}}, {}
    )
