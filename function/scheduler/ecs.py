# -*- coding: utf-8 -*-

"""
ECS service scheduler.

Source: https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start/blob/master/package/scheduler/
"""

import logging
from dataclasses import dataclass
from typing import Dict, Iterator, List, Any

import boto3
from botocore.exceptions import ClientError


logger = logging.getLogger()


@dataclass
class ECSService:
    """ECS service"""

    service_name: str
    cluster_name: str
    ecs: Any

    def stop(self) -> None:
        """
        Stop AWS ECS service
        """
        try:
            self.ecs.update_service(
                cluster=self.cluster_name, service=self.service_name, desiredCount=0
            )
        except Exception as e:
            logger.warn(e)

    def start(self, terminate: bool = True) -> None:
        """
        Start AWS ECS service
        """
        try:
            self.ecs.update_service(
                cluster=self.cluster_name, service=self.service_name, desiredCount=1
            )
        except Exception as e:
            logger.warn(e)


def list_ecs_services_by_tags(tag_key: str, tag_value: str) -> List[ECSService]:
    """
    Aws ECS service list function.
    """

    ecs = boto3.client("ecs")
    rgta = boto3.client("resourcegroupstaggingapi")

    ecs_list = []
    paginator = rgta.get_paginator("get_resources")
    page_iterator = paginator.paginate(
        TagFilters=[{"Key": tag_key, "Values": [tag_value]}],
        ResourceTypeFilters=["ecs:service"],
    )
    for page in page_iterator:
        for resource_tag_map in page["ResourceTagMappingList"]:
            ecs_list.append(
                ECSService(
                    cluster_name=resource_tag_map["ResourceARN"].split("/")[-2],
                    service_name=resource_tag_map["ResourceARN"].split("/")[-1],
                    ecs=ecs,
                )
            )

    return ecs_list
