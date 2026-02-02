#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00cc66d18f8b21fdf"
ZONE_ID="Z0700843M2YZ13RK7XZQ"
DOMAIN_NAME="dev28p.online"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"  # mongodb.dev28p.online
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID  \
    --change-batch '
  {  
       "Comment": "Updating record set"
       ,"Changes": [{ 
	   ,"Action"              : "CREATE"
	   ,"ResourceRecordSet"   : { 
	       "Name"             : "$RECORD_NAME"
		   ,"Type"            : "A"
		   ,"TTL"             : 1
		   ,"ResourceRecords" : [ { 
		    "Value": "$IP)" 
			}] 
		} 
		} ] 
  }
  '
done