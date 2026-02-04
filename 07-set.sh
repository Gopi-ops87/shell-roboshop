#!/bin/bash

set -e

error(){

    echo "There is an error"
}

trap error ERR

echo "Hello"
echo "Hi"
jbwbddchve
echo "Bye"