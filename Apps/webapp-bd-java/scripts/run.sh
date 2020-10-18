#!/usr/bin/env bash

if [ -z "${DATABASE_HOST}" ]; then 
    echo "DATABASE_HOST environment variable is mandatory";
    exit 1;
fi

./wait-for-it.sh ${DATABASE_HOST}:${DATABASE_PORT:=3306} --strict --timeout=300 -- java -jar app.jar