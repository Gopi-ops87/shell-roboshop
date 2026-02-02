#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00cc66d18f8b21fdf"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids sg-00cc66d18f8b21fdf --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' --query 'Instances[0].InstanceId' --output text)

    if [ $instance -ne "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids i-00a9d2ea230cc7d36 --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids i-00a9d2ea230cc7d36 --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    fi

    echo "$instance: $IP"
done