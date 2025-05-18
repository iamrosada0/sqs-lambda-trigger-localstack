#!/bin/bash

# Nome do binário e arquivo zip
BINARY_NAME="bootstrap"
ZIP_NAME="function.zip"

# Caminho atual
WORKDIR=$(pwd)

echo "Compilando o binário $BINARY_NAME usando Docker golang:1.21..."

docker run --rm -v "$WORKDIR":/src -w /src golang:1.21 bash -c "GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o $BINARY_NAME main.go"

if [ $? -ne 0 ]; then
  echo "Erro na compilação."
  exit 1
fi

echo "Compactando o binário em $ZIP_NAME..."

zip -j "$ZIP_NAME" "$BINARY_NAME"

if [ $? -ne 0 ]; then
  echo "Erro ao criar o arquivo zip."
  exit 1
fi

echo "Build e compactação finalizados com sucesso."
