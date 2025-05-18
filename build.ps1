docker run --rm -v ${PWD}:/src -w /src golang:1.21 bash -c "GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap main.go"

Compress-Archive -Path .\bootstrap -DestinationPath function.zip -Force
