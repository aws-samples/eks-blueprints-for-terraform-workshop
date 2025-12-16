#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <image_filename>"
    exit 1
fi

IMAGE_FILE="$1"

cp "./static/images-old/$IMAGE_FILE" "./static/images/"

echo "Copied $IMAGE_FILE from ./static/images-old/ to ./static/images/"
