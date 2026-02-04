#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_IP="mongodb.dev28p.onine"

mkdir -p $LOGS_FOLDER


echo "script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "ERROR:: please use root access"
    exit 1  # failure is other than 0
fi


VALIDATE() {   #function to receive inputs through args just like shell script args
            if [ $1 -ne 0 ]; then
                echo -e "$2 ....$R failure $N" | tee -a $LOG_FILE
                exit 1
            else
                echo -e "$2.. $G  success $N" | tee -a $LOG_FILE
            fi
}

dnf module disable nodejs -y
VALIDATE $? "Disabling mongodb"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling mongodb"


dnf install nodejs -y
VALIDATE $? "installing mongodb"


useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "creating system user"

mkdir /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue application"

cd /app 
VALIDATE $? "Changin app directory"

unzip /tmp/catalogue.zip
VALIDATE $? "unzip catalogue"


npm install 
VALIDATE $? "install dependies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy systemstl service"

systemctl daemon-reload
systemctl enable catalogue 
VALIDATE $? "enable catalogue"

systemctl start catalogue
VALIDATE $? "start catalogue"


cp mono.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo repo"

dnf install mongodb-mongosh -y
VALIDATE $? "install mongodb client"

mongosh --host $MONGODB_IP </app/db/master-data.js
VALIDATE $? "load catalogue products"

systemctl restart catalogue
VALIDATE $? "catalogue service restarted"
