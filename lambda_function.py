import json

def lambda_handler(event, context):
    for record in event.get('Records', []):
        body = record.get('body', '{}')
        print("Mensagem recebida:", body)
        # Se quiser acessar o conteúdo JSON dentro da mensagem:
        try:
            data = json.loads(body)
            print("Conteúdo da mensagem:", data)
            name = data.get("name", "Mundo")
        except json.JSONDecodeError:
            name = "Mundo"

        print(f"Hello {name}!")

    return {
        "statusCode": 200,
        "body": f"Hello {name}!"
    }
