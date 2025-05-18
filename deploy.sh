#!/bin/bash

set -e

# Credenciais falsas para rodar com LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

ENDPOINT="http://localhost:4566"
REGION="us-east-2"
QUEUE_NAME="minha-fila"
FUNCTION_NAME="ConsumidorGoLambda"

echo "Criando fila SQS..."
aws --endpoint-url=$ENDPOINT --region $REGION \
    sqs create-queue --queue-name $QUEUE_NAME

echo "Construindo Lambda..."
./build.sh

echo "Criando função Lambda..."
aws --endpoint-url=$ENDPOINT --region $REGION \
    lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime go1.x \
    --handler main \
    --zip-file fileb://function.zip \
    --role arn:aws:iam::000000000000:role/lambda-role

echo "Vinculando Lambda à fila..."
aws --endpoint-url=$ENDPOINT --region $REGION \
    lambda create-event-source-mapping \
    --function-name $FUNCTION_NAME \
    --batch-size 1 \
    --event-source-arn arn:aws:sqs:$REGION:000000000000:$QUEUE_NAME

echo "Tudo pronto! Envie uma mensagem com:"
echo "aws --endpoint-url=$ENDPOINT --region $REGION sqs send-message --queue-url $ENDPOINT/000000000000/$QUEUE_NAME --message-body 'Hello from Go!'"
