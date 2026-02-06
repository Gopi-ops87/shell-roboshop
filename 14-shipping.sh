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


dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "User already exist ... $Y Skipping $N"
fi


mkdir -p /app
VALIDATE $? "creating app directory"
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping appliaction"
cd /app 
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "removing existing data"
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unziping into temp loc"
mvn clean package &>>$LOG_FILE
VALIDATE $? "Installing packages"
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copying shpping services"

systemctl daemon-reload
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabling shipping service"
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping service"


dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h $MYSQL_IP -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [$? -ne 0 ]; then 

mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE

else
echo -e "Shipping data is already loaded ... $Y skipping $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping service"


END_TIME=$(date +%S)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Total execution time is: $Y $TOTAL_TIME seconds $N"
