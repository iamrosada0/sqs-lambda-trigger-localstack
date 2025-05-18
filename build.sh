#!/bin/bash

GOOS=linux GOARCH=amd64 go build -o main function.go
zip function.zip main
rm main
