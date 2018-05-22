#!/bin/bash

#Go to the current file folder
cd "$(dirname "$0")"
cd ..

echo "* $(basename "$0")"
echo " - Building image"
docker build -t "rogersantos/publisher" .

