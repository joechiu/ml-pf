#!/bin/bash

. ../fun.inc

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
ENV=.env

[ -e $ENV ] && rm $ENV

# Load current environment
if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "Error: $ENV_FILE not exists!"
    exit
fi

update_env() {
    local key="$1"
    local value="$2"
    echo "export ${key}=\"${value}\"" >> "$ENV"
}

prompt_update() {
    local key="$1"
    local current="$2"
    local value
    read -r -p "${key//_/ } [$current]: " value </dev/tty
    [[ -z "$value" ]] && value="$current"
    update_env "$key" "$value"
}
echo source $ENV_FILE

echo "Update configuration (press Enter to keep current value)"
echo

yn

while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

    # Remove surrounding quotes
    value="${value%\"}"
    value="${value#\"}"

    prompt_update "$key" "$value"
done < "$ENV_FILE"

# Reload updated values
set -a
source "$ENV"
set +a

# Derived variables (not written to .env)
IMAGE_NAME="${TOOL_NAME}-tool1-flow"
ENDPOINT_NAME="${TOOL_NAME}-tool1-flow"
ENVIRONMENT_NAME="$IMAGE_NAME"
ENVIRONMENT_YAML="environment-${TOOL_NAME}.yml"
DEPLOYMENT_YAML="deployment-${TOOL_NAME}.yml"
ENDPOINT_YAML="endpoint-${TOOL_NAME}.yml"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
FULL_IMAGE="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"

prompt_update IMAGE_NAME        $IMAGE_NAME        
prompt_update ENDPOINT_NAME     $ENDPOINT_NAME     
prompt_update ENVIRONMENT_NAME  $ENVIRONMENT_NAME  
prompt_update ENVIRONMENT_YAML  $ENVIRONMENT_YAML
prompt_update DEPLOYMENT_YAML   $DEPLOYMENT_YAML   
prompt_update ENDPOINT_YAML     $ENDPOINT_YAML     
prompt_update ACR_LOGIN_SERVER  $ACR_LOGIN_SERVER  
prompt_update FULL_IMAGE        $FULL_IMAGE        

echo 
. $ENV
echo "-- environment variables exported:"
cat $ENV



