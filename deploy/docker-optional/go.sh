#!/bin/bash

echo "Build docker image '$IMAGE_NAME' into ACR '$ACR_NAME' as '$FULL_IMAGE'..."
. ../fun.inc
yn

########################################
# Login to ACR
########################################

echo "Logging into ACR..."
echo az acr login --name "$ACR_NAME"

########################################
# Build only if image doesn't exist
########################################

echo "Checking if image exists in ACR..."

if az acr repository show-tags \
    --name "$ACR_NAME" \
    --repository "$IMAGE_NAME" \
    --query "[?@=='$IMAGE_TAG']" \
    -o tsv | grep -qx "$IMAGE_TAG"
then

    echo "Image already exists:"
    echo "  $FULL_IMAGE"
    echo "Skipping build and push."

else

    echo "Image $IMAGE_NAME not found in ACR $ACR_NAME."
    echo "Building image..."

    docker build \
        -t "$FULL_IMAGE" \
        .

    echo "Pushing image..."

    echo docker push "$FULL_IMAGE"

    echo
    echo "=================================="
    echo "Image pushed successfully:"
    echo "$FULL_IMAGE"
    echo "=================================="

fi


