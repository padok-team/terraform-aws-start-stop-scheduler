# -*- coding: utf-8 -*-

"""
Autoscaling instances scheduler.

Source: https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start/blob/master/package/scheduler/autoscaling_handler.py
"""
import logging
from dataclasses import dataclass
from typing import Dict, Iterator, List, Any

import boto3
from botocore.exceptions import ClientError


logger = logging.getLogger()


@dataclass
class AutoScalingGroup:
    """Autoscaling group"""

    name: str
    ec2: Any
    asg: Any

    def stop(self, terminate=True) -> None:
        """
        Aws autoscaling suspend function.

        Suspend autoscaling group and stop its instances
        with defined tag.
        """
        instance_id_list = self._list_instances()

        try:
            self.asg.suspend_processes(AutoScalingGroupName=self.name)
            logger.info("Suspend autoscaling group {0}".format(self.name))
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

    def start(self, terminate: bool = True) -> None:
        """
        Aws autoscaling resume function.

        Resume autoscaling group and start its instances
        with defined tag.
        """

        # Start autoscaling instance
        if not (terminate):
            instance_id_list = self._list_instances()
            instance_running_ids = []

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
            self.asg.resume_processes(AutoScalingGroupName=self.name)
            logger.info("Resume autoscaling group {0}".format(self.name))
        except ClientError as exc:
            # ec2_exception("autoscaling group", asg_name, exc)
            logger.warn(exc)

    def _list_instances(self) -> Iterator[str]:
        """Aws autoscaling instance list function.

        List name of all instances in the autoscaling group
        and return it in list.

        :param list asg_name:
            The name of the Auto Scaling group.

        :yield Iterator[str]:
            The names of the instances in Auto Scaling group.
        """
        if not self.name:
            return iter([])
        paginator = self.asg.get_paginator("describe_auto_scaling_groups")

        for page in paginator.paginate(AutoScalingGroupNames=[self.name]):
            for scalinggroup in page["AutoScalingGroups"]:
                for instance in scalinggroup["Instances"]:
                    yield instance["InstanceId"]


def list_asg_by_tags(tag_key: str, tag_value: str) -> List[AutoScalingGroup]:
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

    asgs = []

    # Standard ASG
    asg = boto3.client("autoscaling")
    ec2 = boto3.client("ec2")
    paginator = asg.get_paginator("describe_auto_scaling_groups")

    for page in paginator.paginate():
        for group in page["AutoScalingGroups"]:
            for tag in group["Tags"]:
                if tag["Key"] == tag_key and tag["Value"] == tag_value:
                    asgs.append(
                        AutoScalingGroup(
                            name=group["AutoScalingGroupName"], ec2=ec2, asg=asg
                        )
                    )
    # ASG from Node Group
    eks = boto3.client('eks')

    paginator_list_clusters = eks.get_paginator('list_clusters')
    paginator_list_nodegroups = eks.get_paginator('list_nodegroups')

    ## List clusters
    clusters = []
    for page in paginator_list_clusters.paginate():
        clusters += page['clusters']

    ## List nodegroups per cluster
    list_clusters_node_groups = []
    for cluster in clusters:
        for page in paginator_list_nodegroups.paginate(clusterName = cluster):
             list_clusters_node_groups.append({'cluster_name':cluster, 'node_groups': page['nodegroups']})
    
    ## List node group with tags
    node_group_with_tag = []
    for association in list_clusters_node_groups:
        for node_group_name in association['node_groups']:
            node_group_info = eks.describe_nodegroup(
                clusterName = association['cluster_name'],
                nodegroupName = node_group_name
            )
            tags = node_group_info['nodegroup']['tags']
            try:
                value = tags[tag_key]
            except:
                pass
            else:
                if value == tag_value:
                    node_group_with_tag.append(node_group_info['nodegroup'])

    ## List ASG with tags
    for node_group in node_group_with_tag:
        for aut_scaling_group in node_group['resources']['autoScalingGroups']:
            asgs.append(
                AutoScalingGroup(
                    name=aut_scaling_group['name'], ec2=ec2, asg=asg
                )
            )
    return asgs
