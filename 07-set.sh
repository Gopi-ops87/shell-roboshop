#!/bin/bash

set -e

error(){

    echo "There is an error in $LINENO, Command is: $BASH_COMMAND"
}

trap error ERR

echo "Hello"
echo "Hi"
jbwbddchve
echo "Bye"