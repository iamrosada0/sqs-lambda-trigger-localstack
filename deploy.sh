#!/bin/bash

set -e

QUEUE_NAME="minha-fila"
FUNCTION_NAME="ConsumidorGoLambda"

echo "Criando fila SQS..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs create-queue --queue-name $QUEUE_NAME

echo "Construindo Lambda..."
./build.sh

echo "Criando função Lambda..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime go1.x \
  --handler main \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::000000000000:role/lambda-role

echo "Vinculando Lambda à fila..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT lambda create-event-source-mapping \
  --function-name $FUNCTION_NAME \
  --batch-size 1 \
  --event-source-arn arn:aws:sqs:$AWS_DEFAULT_REGION:000000000000:$QUEUE_NAME

echo "Tudo pronto! Envie uma mensagem com:"
echo "aws --endpoint-url=$LOCALSTACK_ENDPOINT sqs send-message --queue-url $LOCALSTACK_ENDPOINT/000000000000/$QUEUE_NAME --message-body 'Hello from Go!'"
