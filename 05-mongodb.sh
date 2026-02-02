#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER


echo "script started executed at: $(date)"

if [ $USER_ID -ne 0 ]; then
    echo "ERROR:: please use root access"
    echo "ERROR:: please use root access" &>>"$LOG_FILE"
    exit 1
fi


VALIDATE() {
            if [ $1 -ne 0 ]; then
                echo -e "ERROR:: $2 ....$R installation is failed $N"
                echo -e "ERROR:: $2 ....$R installation is failed $N" &>>"$LOG_FILE"
                exit 1
            else
                echo -e "$2.. $G  success $N"
                echo -e "$2.. $G  success $N" &>>"$LOG_FILE"
            fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y  &>> "$LOG_FILE"
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>> "$LOG_FILE"
VALIDATE $? "Enable MongoDB"

systemctl start mongod &>> "$LOG_FILE"
VALIDATE $? "Started MongoDB"
