# -*- coding: utf-8 -*-

"""
EC2 instances scheduler.
"""
import logging
from dataclasses import dataclass
from typing import Dict, Iterator, List, Any

import boto3
from botocore.exceptions import ClientError


logger = logging.getLogger()


@dataclass
class EC2Instance:
    """EC2 Instance"""

    instance_id: str
    ec2: Any

    def stop(self) -> None:
        """
        Stop AWS EC2 instance
        """
        try:
            self.ec2.stop_instances(InstanceIds=[self.instance_id])
            logger.info(f"Stopped EC2 instance {self.instance_id}")
        except ClientError as exc:
            logger.warn(exc)


def list_ec2_by_tags(tag_key: str, tag_value: str) -> List[EC2Instance]:
    """
    List AWS EC2 instances with the specified tag key and value.
    """

    ec2 = boto3.client("ec2")
    rgta = boto3.client("resourcegroupstaggingapi")

    ec2_list = []
    paginator = rgta.get_paginator("get_resources")
    page_iterator = paginator.paginate(
        TagFilters=[{"Key": tag_key, "Values": [tag_value]}],
        ResourceTypeFilters=["ec2:instance"],
    )

    for page in page_iterator:
        for resource_tag_map in page["ResourceTagMappingList"]:
            instance_id = resource_tag_map["ResourceARN"].split(":")[-1].split("/")[-1]
            ec2_list.append(EC2Instance(instance_id=instance_id, ec2=ec2))

    return ec2_list
