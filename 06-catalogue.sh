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
SCRIPT_DIR=$PWD

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling mongodb"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling mongodb"


dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing mongodb"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo "User already exist ... $Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"

cd /app 
VALIDATE $? "Changin app directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"


npm install  &>>$LOG_FILE
VALIDATE $? "install dependies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy systemstl service"

systemctl daemon-reload
systemctl enable catalogue 
VALIDATE $? "enable catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "start catalogue"



cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "install mongodb client"

mongosh --host $MONGODB_IP </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "load catalogue products"

systemctl restart catalogue
VALIDATE $? "catalogue service restarted"
