#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
INSTANCE_TYPE="t3.micro"
SG_ID="sg-00cc66d18f8b21fdf"
ZONE_ID="Z0700843M2YZ13RK7XZQ"
DOMAIN_NAME="dev28p.online"

for instance in "$@"
do
    echo "Creating instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [[ "$instance" != "frontend" ]]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance: $IP"

    aws route53 change-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --change-batch <<EOF
{
  "Comment": "Updating record set for $instance",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF

done
