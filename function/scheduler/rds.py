# -*- coding: utf-8 -*-

"""
RDS instances scheduler.

Source: https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start/blob/master/package/scheduler/
"""
import logging
from dataclasses import dataclass
from typing import Dict, Iterator, List, Any

import boto3
from botocore.exceptions import ClientError


logger = logging.getLogger()


@dataclass
class RDSInstance:
    """RDS Instance"""

    db_id: str
    rds: Any

    def stop(self) -> None:
        """
        Stop AWS RDS instance
        """
        try:
            self.rds.stop_db_instance(DBInstanceIdentifier=self.db_id)
        except Exception as e:
            logger.warn(e)

    def start(self, terminate: bool = True) -> None:
        """
        Start AWS RDS instance
        """
        try:
            self.rds.start_db_instance(DBInstanceIdentifier=self.db_id)
        except Exception as e:
            logger.warn(e)


def list_rds_by_tags(tag_key: str, tag_value: str) -> List[RDSInstance]:
    """
    Aws RDS list function.
    """

    rds = boto3.client("rds")
    rgta = boto3.client("resourcegroupstaggingapi")

    rds_list = []
    paginator = rgta.get_paginator("get_resources")
    page_iterator = paginator.paginate(
        TagFilters=[{"Key": tag_key, "Values": [tag_value]}],
        ResourceTypeFilters=["rds:db"],
    )
    for page in page_iterator:
        for resource_tag_map in page["ResourceTagMappingList"]:
            rds_list.append(
                RDSInstance(
                    db_id=resource_tag_map["ResourceARN"].split(":")[-1], rds=rds
                )
            )

    return rds_list
