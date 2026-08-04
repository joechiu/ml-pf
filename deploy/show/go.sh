#!/bin/bash

show() {
    local key="$1"
    echo "$key=${!key}"
}

ENV=../config/.env
while IFS='=' read -r key value; do

    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    key="${key#export }"

    value="${value%\"}"
    value="${value#\"}"

    echo "$key = '$value'"

done < $ENV
