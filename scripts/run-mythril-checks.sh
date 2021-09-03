#!/bin/bash

if [ ${CI:=''} ]; then
    echo "CI environment detected, trying to run myth command"
else
    echo "Local environment detected, trying to run myth using docker"
fi

for contract_path in $(find ./contracts -type f -name "*.sol"); do
  contract_file=$(basename $contract_path)
  echo "Performing Security Analisys for contract: $contract_file"
  
  if [ ${CI:=''} ]; then
    myth analyze "$(pwd)/flatten/$contract_file"
  else
    docker run -v "$(pwd)/flatten/$contract_file:/tmp/$contract_file" mythril/myth analyze "/tmp/$contract_file"
  fi
done