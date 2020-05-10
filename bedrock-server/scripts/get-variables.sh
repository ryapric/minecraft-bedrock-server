#!/usr/bin/env bash

accountNumber=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-${accountNumber}"

printf "accountNumber = %s\nbucket = %s\n" "${accountNumber}" "${bucket}"
