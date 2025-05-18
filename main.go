package main

import (
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// Defina a struct de acordo com o JSON esperado na mensagem SQS
type Mensagem struct {
	ID       string `json:"id"`
	Conteudo string `json:"conteudo"`
}

func handler(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, record := range sqsEvent.Records {
		var msg Mensagem
		err := json.Unmarshal([]byte(record.Body), &msg)
		if err != nil {
			log.Printf("Erro ao decodificar mensagem JSON: %v", err)
			continue // Pula essa mensagem e continua com as outras
		}

		log.Printf("Mensagem recebida - ID: %s, Conteudo: %s", msg.ID, msg.Conteudo)
	}
	return nil
}

func main() {
	lambda.Start(handler)
}
