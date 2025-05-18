#!/bin/bash
set -e

# Configuração AWS para LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-2
export LOCALSTACK_ENDPOINT=http://localhost:4566

echo "1. Build do binário e zip..."
docker-compose run --rm builder

echo "2. Subindo LocalStack..."
docker-compose up -d localstack

echo "Aguardando LocalStack iniciar..."
until aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION sqs list-queues >/dev/null 2>&1; do
  echo -n "."
  sleep 2
done
echo " LocalStack está rodando."

echo "3. Verificando se a fila SQS 'minha-fila' existe..."
if aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION sqs get-queue-url --queue-name minha-fila >/dev/null 2>&1; then
  echo "Fila SQS 'minha-fila' já existe."
else
  echo "Criando fila SQS 'minha-fila'..."
  aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION sqs create-queue --queue-name minha-fila
fi

echo "4. Verificando se a função Lambda 'minha-funcao' existe..."
if aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION lambda get-function --function-name minha-funcao >/dev/null 2>&1; then
  echo "Função Lambda 'minha-funcao' já existe. Removendo..."
  aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION lambda delete-function --function-name minha-funcao
else
  echo "Função Lambda 'minha-funcao' não existe."
fi

echo "5. Criando função Lambda 'minha-funcao'..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION lambda create-function \
  --function-name minha-funcao \
  --runtime provided.al2 \
  --role arn:aws:iam::000000000000:role/lambda-execute \
  --handler bootstrap \
  --zip-file fileb://function.zip \
  --architectures "x86_64"

echo "6. Verificando se existe mapeamento de evento para 'minha-funcao'..."
QUEUE_URL=http://localhost:4566/000000000000/minha-fila
QUEUE_ARN=$(aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

MAPPING_UUID=$(aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION lambda list-event-source-mappings \
  --function-name minha-funcao \
  --query "EventSourceMappings[?EventSourceArn=='$QUEUE_ARN'].UUID" \
  --output text)

if [ -n "$MAPPING_UUID" ]; then
  echo "Mapeamento de evento já existe (UUID: $MAPPING_UUID). Removendo..."
  aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION lambda delete-event-source-mapping --uuid $MAPPING_UUID
else
  echo "Nenhum mapeamento de evento encontrado para a fila SQS."
fi

echo "7. Criando event source mapping para ligar SQS à Lambda..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT --region $AWS_DEFAULT_REGION lambda create-event-source-mapping \
  --function-name minha-funcao \
  --batch-size 1 \
  --event-source-arn $QUEUE_ARN

echo "✅ Deploy finalizado com sucesso!"