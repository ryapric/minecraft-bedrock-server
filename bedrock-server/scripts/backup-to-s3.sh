#!/usr/bin/env bash

source get-variables.sh

bakfile="bedrock-server-backup.tar.gz"

# Only backup to S3 if files were actually modified in the last 15 minutes. This
# should save on S3 transfer costs.
modifiedFiles=$(docker exec bedrock_server sh -c "find /root/worlds -mmin -15 -type f -print")
if [[ "${modifiedFiles}" ]]; then
  docker exec bedrock_server sh -c "tar -czf ${bakfile} worlds"
  docker cp "bedrock_server:/root/${bakfile}" "/root/${bakfile}"
  aws s3 mb "s3://${bucket}" || printf "Backup bucket ${bucket} already exists\n"
  aws s3 cp "/root/${bakfile}" "s3://${bucket}/${bakfile}"
fi
