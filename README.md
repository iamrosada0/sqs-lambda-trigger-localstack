

---

## ✅ Objetivo

* Compilar seu Lambda em Go como binário compatível.
* Rodá-lo localmente dentro do LocalStack.
* Testar a invocação Lambda via `awslocal` ou `curl`.

---

## 📦 Etapa 1: Estrutura esperada pela LocalStack para Lambda custom (Go)

LocalStack espera que a função Lambda tenha:

* Um Docker image customizada OU
* Um zip com binário Go chamado `bootstrap` (quando usa runtime `provided.al2`)

---

## 🛠️ Etapa 2: Compile seu binário como `bootstrap`

```bash
docker run --rm -v ${PWD}:/src -w /src golang:1.24.3 bash -c "CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bootstrap main.go"
```

> O nome **`bootstrap`** é necessário quando você usa o runtime `provided.al2`.

---

## 📦 Etapa 3: Crie um arquivo ZIP com esse binário

```bash
zip function.zip bootstrap
```

---

## 📥 Etapa 4: Suba sua função Lambda para o LocalStack

1. Instale o `awslocal` se ainda não tiver:

```bash
pip install awscli-local
```

2. Crie a função Lambda:

```bash
awslocal lambda create-function \
  --function-name my-go-lambda \
  --runtime provided.al2 \
  --handler bootstrap \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::000000000000:role/lambda-role
```

---

## 🚀 Etapa 5: Invoque a função Lambda

```bash
awslocal lambda invoke --function-name my-go-lambda response.json
cat response.json
```

---

## ✅ Se quiser fazer isso dentro de um script, aqui está:

```bash
#!/bin/bash

set -e

# Build
docker run --rm -v "$PWD":/src -w /src golang:1.24.3 bash -c "CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bootstrap main.go"

# Zip
zip -r function.zip bootstrap

# Create Lambda in LocalStack
awslocal lambda delete-function --function-name my-go-lambda 2>/dev/null || true
awslocal lambda create-function \
  --function-name my-go-lambda \
  --runtime provided.al2 \
  --handler bootstrap \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::000000000000:role/lambda-role

# Invoke
awslocal lambda invoke --function-name my-go-lambda response.json
cat response.json
```

---

## 💡 Dica extra: Visualize os logs

```bash
awslocal logs tail /aws/lambda/my-go-lambda --follow
```

---

