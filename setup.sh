#!/usr/bin/env bash

target_path="$1"
cp ./Makefile ${target_path}
cp ./gitignore ${target_path}/.gitignore
cp ./golangci.yaml ${target_path}/.golangci.yaml
cp -r ./githooks ${target_path}
