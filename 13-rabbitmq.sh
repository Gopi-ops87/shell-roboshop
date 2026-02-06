#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
SCRIPT_DIR=$PWD

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


cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Adding raabitmq repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "installing rabbitmq"
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enabling rabbitmq"
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "starting rabbitmq"
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "adding user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "setting permissions"

END_TIME=$(date +%S)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Total execution time is: $Y $TOTAL_TIME seconds $N"
