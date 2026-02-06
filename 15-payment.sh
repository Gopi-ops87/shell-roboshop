#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_IP="mongodb.dev28p.online"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  # /var/log/shell-roboshop/12-cart.log
MYSQL_IP="mysql.dev28p.online"

mkdir -p &>>$LOG_FILE

START_TIME=$(date +%S)
echo "script started executed at: $(date)" | tee -a &>>$LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "ERROR:: please use root access"
    exit 1  # failure is other than 0
fi


VALIDATE() {   #function to receive inputs through args just like shell script args
            if [ $1 -ne 0 ]; then
                echo -e "$2 ....$R failure $N" | tee -a &>>$LOG_FILE
                exit 1
            else
                echo -e "$2.. $G  success $N" | tee -a &>>$LOG_FILE
            fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "installing pyton"


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "User already exist ... $Y Skipping $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Donloading payment app"
cd /app 
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing existing code"
unzip /tmp/payment.zip &>>$LOG_FILE

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "install dependies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "copy systemstl service"

systemctl daemon-reload
systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enable payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "start payment"

END_TIME=$(date +%S)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Total execution time is: $Y $TOTAL_TIME seconds $N"
