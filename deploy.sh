#!/bin/bash
set -e

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export LOCALSTACK_ENDPOINT=http://localhost:4566

echo "1. Empacotando função Lambda Python via Docker..."
docker build -t lambda-python-builder .
docker run --rm lambda-python-builder > function.zip

echo "2. Subindo LocalStack..."
docker-compose up -d localstack

echo "3. Esperando LocalStack ficar pronto..."
until aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs list-queues > /dev/null 2>&1; do
  echo -n "."
  sleep 2
done
echo " LocalStack está rodando."

echo "4. Criando fila SQS 'minha-fila' se não existir..."
if aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs get-queue-url --queue-name minha-fila > /dev/null 2>&1; then
  echo "Fila já existe."
else
  aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs create-queue --queue-name minha-fila
  echo "Fila criada."
fi

echo "5. Removendo função Lambda 'minha-funcao' se existir..."
if aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda get-function --function-name minha-funcao > /dev/null 2>&1; then
  aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda delete-function --function-name minha-funcao
fi

echo "6. Criando função Lambda 'minha-funcao' (Python)..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda create-function \
  --function-name minha-funcao \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/irrelevant \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip

echo "7. Criando mapeamento de evento (SQS -> Lambda)..."
QUEUE_URL=$(aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs get-queue-url --queue-name minha-fila --output text)
QUEUE_ARN=$(aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

MAPPING_UUID=$(aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda list-event-source-mappings --function-name minha-funcao --query "EventSourceMappings[?EventSourceArn=='$QUEUE_ARN'].UUID" --output text)

if [ -n "$MAPPING_UUID" ]; then
  echo "Mapeamento já existe. Removendo..."
  aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda delete-event-source-mapping --uuid $MAPPING_UUID
fi

aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda create-event-source-mapping \
  --function-name minha-funcao \
  --event-source-arn $QUEUE_ARN \
  --batch-size 1
echo "8. Criando Tabela..."
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name Mensagens \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1

echo "✅ Deploy completo!"
