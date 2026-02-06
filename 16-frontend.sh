#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  # /var/log/shell-roboshop/12-cart.log

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

dnf module disable nginx -y $LOG_FILE
dnf module enable nginx:1.24 -y $LOG_FILE
dnf install nginx -y $LOG_FILE
VALIDATE $? "Installing NGINX"

systemctl enable nginx  $LOG_FILE
systemctl start nginx $LOG_FILE
VALIDATE $? "Starting NGINX"

rm -rf /usr/share/nginx/html/*  $LOG_FILE
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip $LOG_FILE
cd /usr/share/nginx/html $LOG_FILE
unzip /tmp/frontend.zip $LOG_FILE

rm -rf /etc/nginx/nginx.conf $LOG_FILE
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf $LOG_FILE
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx $LOG_FILE
VALIDATE $? "Restarting ngnx"

END_TIME=$(date +%S)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Total execution time is: $Y $TOTAL_TIME seconds $N"
