#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  # /var/log/shell-roboshop/06-catalogue.log

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


dnf module disable redis -y  &>>$LOG_FILE
VALIDATE $? "Disabling redis"
dnf module enable redis:7 -y  &>>$LOG_FILE
VALIDATE $? "enabling redis 7"
dnf install redis -y   &>>$LOG_FILE
VALIDATE $? "Installing redis"
sed -i \
 -e 's/^bind 127.0.0.1/bind 0.0.0.0/' \
  -e 's/^protected-mode yes/protected-mode no/' \
  /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "allowing remote connections"
systemctl enable redis  &>>$LOG_FILE
VALIDATE $? "enabling redis"
systemctl start redis  &>>$LOG_FILE
VALIDATE $? "Starting Redis"

END_TIME=$(date +%S)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Total execution time is: $Y $TOTAL_TIME seconds $N"