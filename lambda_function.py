import json
import boto3
import uuid  # para gerar um ID único para cada item

# Inicializa o cliente DynamoDB (o boto3 vai usar as configs do ambiente)
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Mensagens')

def lambda_handler(event, context):
    for record in event.get('Records', []):
        body = record.get('body', '{}')
        print("Mensagem recebida:", body)
        
        try:
            data = json.loads(body)
            print("Conteúdo da mensagem:", data)
            name = data.get("name", "Mundo")
        except json.JSONDecodeError:
            name = "Mundo"
            data = {}

        # Monta o item para salvar no DynamoDB
        item = {
            'id': str(uuid.uuid4()),   # id único gerado
            'name': name,
            'raw_data': data          # opcional, salva o json completo
        }

        # Salva no DynamoDB
        try:
            table.put_item(Item=item)
            print(f"Item salvo no DynamoDB: {item}")
        except Exception as e:
            print(f"Erro ao salvar no DynamoDB: {e}")

        print(f"Hello {name}!")

    return {
        "statusCode": 200,
        "body": f"Hello {name}!"
    }
