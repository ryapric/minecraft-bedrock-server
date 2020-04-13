#!/usr/bin/env bash

accountNumber=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-${accountNumber}"
bakfile="bedrock-server-backup.tar.gz"

docker exec bedrock_server sh -c "tar -czf ${bakfile} worlds"
docker cp "bedrock_server:/root/${bakfile}" "/root/${bakfile}"
aws s3 mb "s3://${bucket}" || printf "Backup bucket ${bucket} already exists\n"
aws s3 cp "/root/${bakfile}" "s3://${bucket}/${bakfile}"
