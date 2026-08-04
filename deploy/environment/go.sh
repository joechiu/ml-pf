#!/bin/bash


echo "create a new environment '$ENVIRONMENT_NAME'..."

ws=/tmp/ws
[ -d $ws ] || mkdir -p $ws
cp -rf Dockerfile requirements.txt $ws/.

. ../fun.inc
yn

cd $ws

echo "1. setting azure context with SUBSCRIPTION_ID: '$SUBSCRIPTION_ID', RESOURCE_GROUP: '$RESOURCE_GROUP', WORKSPACE: '$WORKSPACE'..."

az account set \
  --subscription "$SUBSCRIPTION_ID"

az configure \
  --defaults \
  group="$RESOURCE_GROUP" \
  workspace="$WORKSPACE"


echo "2. creating AML environment yaml: yaml: '$ENVIRONMENT_YAML', name: '$ENVIRONMENT_NAME'..."

cat > "$ENVIRONMENT_YAML" <<EOF
\$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json

name: $ENVIRONMENT_NAME

build:
  path: .
  dockerfile_path: Dockerfile

description: PromptFlow runtime with tool1 dependencies

inference_config:
  liveness_route:
    path: /
    port: 8080

  readiness_route:
    path: /
    port: 8080

  scoring_route:
    path: /score
    port: 8080

EOF

ls -ltrh
echo "3. check and set the environment version ready"

read -r -p "Input a version if need: " ENVIRONMENT_VERSION

if [ -n "$ENVIRONMENT_VERSION" ]; then
  NEW_VERSION=$ENVIRONMENT_VERSION
else
  LATEST_VERSION=$(
      az ml environment list \
          --name "$ENVIRONMENT_NAME" \
          --query "max_by(@, &to_number(version)).version" \
          -o tsv 2>/dev/null || true
  )

  if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "null" ]]; then
      NEW_VERSION=1
  else
      NEW_VERSION=$((LATEST_VERSION + 1))
      echo "3.1. upgrade $ENVIRONMENT_NAME from version $LATEST_VERSION to version $NEW_VERSION"
  fi
fi
[ -n "$ENVIRONMENT_VERSION" ] && NEW_VERSION=$ENVIRONMENT_VERSION

echo "3.1. upgrade $ENVIRONMENT_NAME to version $NEW_VERSION"

yn

echo "4. creating azure ml environment $ENVIRONMENT_NAME version $NEW_VERSION..."

echo az ml environment create \
    --file "$ENVIRONMENT_YAML" \
    --set version=$NEW_VERSION

echo az ml environment show \
    --name "$ENVIRONMENT_NAME" \
    --version "$NEW_VERSION" \
    --output table

if az ml environment create \
    --file "$ENVIRONMENT_YAML" \
    --set version=$NEW_VERSION; then
    echo "4.1. environment $ENVIRONMENT_NAME version $NEW_VERSION created successfully"

    echo "4.2. verify $ENVIRONMENT_NAME version $NEW_VERSION"
    az ml environment show \
        --name "$ENVIRONMENT_NAME" \
        --version "$NEW_VERSION" \
        --output table
else
    echo "4.1. cannot create environment $ENVIRONMENT_NAME version $NEW_VERSION"
fi

echo
echo "DONE!"


