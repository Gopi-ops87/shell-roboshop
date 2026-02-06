#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGO_IP="mongodb.dev28p.online"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  # /var/log/shell-roboshop/11-user.log

mkdir -p $LOGS_FOLDER

START_TIME=$(date +%S)
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
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs"


dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "User already exist ... $Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user application"

cd /app 
VALIDATE $? "Changing app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"


npm install  &>>$LOG_FILE
VALIDATE $? "install dependies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copy systemstl service"

systemctl daemon-reload
systemctl enable user &>>$LOG_FILE
VALIDATE $? "enable user"

systemctl start user &>>$LOG_FILE
VALIDATE $? "start user"

END_TIME=$(date +%S)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Total execution time is: $Y $TOTAL_TIME seconds $N"
