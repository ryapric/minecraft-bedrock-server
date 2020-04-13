#!/usr/bin/env bash

accountNumber=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-${accountNumber}"
bakfile="bedrock-server-backup.tar.gz"

if aws s3 cp "s3://${bucket}/${bakfile}" "/root/${bakfile}"; then
  # Bit of a hack, but edit the Dockerfile to pull in the backup data if it exists
  sed -E -i "s/(CMD .*)/COPY ${bakfile} .\nRUN tar -xzf ${bakfile}\n\n\1/" /root/Dockerfile
else
  printf "No remote backup data exists or is inaccessible, starting with new World\n"
fi
